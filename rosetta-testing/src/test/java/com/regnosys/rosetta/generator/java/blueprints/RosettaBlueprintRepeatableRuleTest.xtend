package com.regnosys.rosetta.generator.java.blueprints

import com.regnosys.rosetta.tests.RosettaInjectorProvider
import com.regnosys.rosetta.tests.util.CodeGeneratorTestHelper
import com.regnosys.rosetta.tests.util.ModelHelper
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.hamcrest.CoreMatchers
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static com.regnosys.rosetta.rosetta.simple.SimplePackage.Literals.*
import static org.hamcrest.MatcherAssert.*
import static org.junit.jupiter.api.Assertions.*
import javax.inject.Inject

@InjectWith(RosettaInjectorProvider)
@ExtendWith(InjectionExtension)
class RosettaBlueprintRepeatableRuleTest {

	@Inject extension CodeGeneratorTestHelper
	@Inject extension ModelHelper
	@Inject extension ValidationTestHelper
	
	@Test
	def void shouldParseReportWithRepeatableComplexTypeRuleThenExtractRule() {
		'''
			body Authority TEST_REG
			corpus TEST_REG MiFIR
			
			report TEST_REG MiFIR in T+1
			from Bar
			when FooRule
			with type BarReport
			
			type BarReport:
			    bazList BazReport (0..*)
			        [ruleReference RepeatableBarBazList]
			
			type BazReport:
				field string (1..1)
					[ruleReference BazField]
			
			type Bar:
				bazList Baz (0..*)
			
			type Baz:
				field string (1..1)
			
			eligibility rule FooRule from Bar:
				filter bazList exists

			reporting rule RepeatableBarBazList from Bar:
				[legacy-syntax]
				extract repeatable Bar->bazList then
				(
					BazField
				)
			
			reporting rule BazField from Baz:
				extract field
		'''
		.parseRosettaWithNoIssues
	}
	
	@Test
	def void shouldParseReportAndGenerateDuplicateRuleError() {
		'''
			body Authority TEST_REG
			corpus TEST_REG MiFIR
			
			report TEST_REG MiFIR in T+1
			from Bar
			when FooRule
			with type BarReport
			
			type BarReport:
			    bazList BazReport (0..*)
			        [ruleReference RepeatableBarBazList]
			    bazField string (1..1)
			    	[ruleReference BazField]
			
			type BazReport:
				field string (1..1)
					[ruleReference BazField]
			
			type Bar:
				bazList Baz (1..*)
			
			type Baz:
				field string (1..1)
			
			eligibility rule FooRule from Bar:
				filter bazList exists

			reporting rule RepeatableBarBazList from Bar:
				[legacy-syntax]
				extract repeatable Bar->bazList then
				(
					BazField
				)
			
			reporting rule BazField from Baz:
				extract field
		'''
		.parseRosetta.assertError(ROSETTA_RULE_REFERENCE, null, "Duplicate reporting rule BazField")
	}
	

	@Test
	def void shouldGenerateRepeatableExtractCode() {
		val code = '''
			type Foo:
				listAttr int (1..*)
			
			reporting rule RepeatableValue from Foo:
				[legacy-syntax]
				[regulatoryReference ESMA MiFIR RTS_22 annex "" provision ""]
				extract repeatable Foo -> listAttr as "Repeating Value"
			
		'''.generateCode
		//println(code)
		val blueprintJava = code.get("com.rosetta.test.model.blueprint.RepeatableValueRule")
		// writeOutClasses(blueprint, "repeatableExtract");
		try {
			assertThat(blueprintJava, CoreMatchers.notNullValue())
			val expected = '''
				package com.rosetta.test.model.blueprint;
				
				import com.regnosys.rosetta.blueprints.Blueprint;
				import com.regnosys.rosetta.blueprints.BlueprintInstance;
				import com.regnosys.rosetta.blueprints.runner.actions.rosetta.RosettaActionFactory;
				import com.regnosys.rosetta.blueprints.runner.data.RuleIdentifier;
				import com.rosetta.model.lib.mapper.MapperS;
				import com.rosetta.test.model.Foo;
				import javax.inject.Inject;
				
				import static com.regnosys.rosetta.blueprints.BlueprintBuilder.*;
				
				/**
				 * @version test
				 */
				public class RepeatableValueRule<INKEY> implements Blueprint<Foo, Integer, INKEY, INKEY> {
					
					private final RosettaActionFactory actionFactory;
					
					@Inject
					public RepeatableValueRule(RosettaActionFactory actionFactory) {
						this.actionFactory = actionFactory;
					}
					
					@Override
					public String getName() {
						return "RepeatableValue"; 
					}
					
					@Override
					public String getURI() {
						return "__synthetic1.rosetta#com.rosetta.test.model.RepeatableValue";
					}
					
					
					@Override
					public BlueprintInstance<Foo, Integer, INKEY, INKEY> blueprint() {
						return 
							startsWith(actionFactory, actionFactory.<Foo, Integer, INKEY>newRosettaRepeatableMapper("__synthetic1.rosetta#/0/@elements.1/@nodes/@node", "Foo->listAttr", new RuleIdentifier("Repeating Value", getClass()), foo -> MapperS.of(foo).<Integer>mapC("getListAttr", _foo -> _foo.getListAttr())))
							.toBlueprint(getURI(), getName());
					}
				}
			'''
			code.compileToClasses
			assertEquals(expected, blueprintJava)
		} finally {
		}
	}
}
