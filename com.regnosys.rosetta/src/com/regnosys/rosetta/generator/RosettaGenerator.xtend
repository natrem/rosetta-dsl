/*

 * generated by Xtext 2.10.0
 */
package com.regnosys.rosetta.generator

import com.google.inject.Inject
import com.regnosys.rosetta.generator.daml.enums.DamlEnumGenerator
import com.regnosys.rosetta.generator.daml.object.DamlModelObjectGenerator
import com.regnosys.rosetta.generator.java.RosettaJavaPackages
import com.regnosys.rosetta.generator.java.blueprints.BlueprintGenerator
import com.regnosys.rosetta.generator.java.calculation.CalculationGenerator
import com.regnosys.rosetta.generator.java.enums.EnumGenerator
import com.regnosys.rosetta.generator.java.object.MetaFieldGenerator
import com.regnosys.rosetta.generator.java.object.ModelMetaGenerator
import com.regnosys.rosetta.generator.java.object.ModelObjectGenerator
import com.regnosys.rosetta.generator.java.qualify.QualifyFunctionGenerator
import com.regnosys.rosetta.generator.java.rule.ChoiceRuleGenerator
import com.regnosys.rosetta.generator.java.rule.DataRuleGenerator
import com.regnosys.rosetta.rosetta.RosettaClass
import com.regnosys.rosetta.rosetta.RosettaEnumeration
import com.regnosys.rosetta.rosetta.RosettaEvent
import com.regnosys.rosetta.rosetta.RosettaMetaType
import com.regnosys.rosetta.rosetta.RosettaModel
import com.regnosys.rosetta.rosetta.RosettaProduct
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import com.regnosys.rosetta.generator.external.ExternalGenerators
import org.apache.log4j.Logger
import com.regnosys.rosetta.generator.java.function.FunctionGenerator
import com.rosetta.util.DemandableLock

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class RosettaGenerator extends AbstractGenerator {
	static Logger LOGGER = Logger.getLogger(RosettaGenerator)

	@Inject ModelObjectGenerator modelObjectGenerator
	@Inject EnumGenerator enumGenerator
	@Inject ModelMetaGenerator metaGenerator
	@Inject ChoiceRuleGenerator choiceRuleGenerator
	@Inject DataRuleGenerator dataRuleGenerator
	@Inject CalculationGenerator calculationGenerator
	@Inject FunctionGenerator functionGenerator
	@Inject BlueprintGenerator blueprintGenerator
	@Inject QualifyFunctionGenerator<RosettaEvent> qualifyEventsGenerator
	@Inject QualifyFunctionGenerator<RosettaProduct> qualifyProductsGenerator
	//@Inject ClassListGenerator classListGenerator
	@Inject MetaFieldGenerator metaFieldGenerator
	@Inject DamlModelObjectGenerator damlModelObjectGenerator
	@Inject DamlEnumGenerator damlEnumGenerator
	@Inject ExternalGenerators externalGenerators
	
	// For files that are
	val ignoredFiles = #{'model-no-code-gen.rosetta'}
	
	val lock = new DemandableLock;

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		// println("Starting the main generate method for "+resource.URI.toString)  
		try {
			lock.getWriteLock(true);
		if (!ignoredFiles.contains(resource.URI.segments.last)) {	
			// generate for each model object
			resource.contents.filter(RosettaModel).forEach [
				val packages = new RosettaJavaPackages(header.namespace)
				val version = header.version
				
				modelObjectGenerator.generate(packages, fsa, elements, version)
				enumGenerator.generate(packages, fsa, elements, version)
				choiceRuleGenerator.generate(packages, fsa, elements, version)
				dataRuleGenerator.generate(packages, fsa, elements, version)
				metaGenerator.generate(packages, fsa, elements, version)
				calculationGenerator.generate(packages, fsa, elements, version)
				functionGenerator.generate(packages, fsa, elements, version)
				blueprintGenerator.generate(packages, fsa, elements, version)
				qualifyEventsGenerator.generate(packages, fsa, elements, packages.qualifyEvent, RosettaEvent, version)
				qualifyProductsGenerator.generate(packages, fsa, elements, packages.qualifyProduct, RosettaProduct, version)
				
				val models = resource.resourceSet.resources.flatMap[contents].filter(RosettaModel).toList
				val allElements = models.flatMap[elements].toList
				metaFieldGenerator.generate(fsa, allElements.filter(RosettaMetaType), elements.filter(RosettaClass), models.map[header].filter(a|a!==null).map[namespace])
	
				// Invoke externally defined code generators
				externalGenerators.forEach[generator |
					generator.generate(packages, elements, version,[map|
						map.entrySet.forEach[fsa.generateFile(key, generator.outputConfiguration.getName, value)]],resource, lock)
				]
			]
				
			val model = resource.resourceSet.resources.flatMap[contents].filter(RosettaModel)
			val version = model.findFirst[header!==null].header.version
			val elements = model.flatMap[elements]
			damlModelObjectGenerator.generate(fsa, elements.filter(RosettaClass), elements.filter(RosettaMetaType), version)
			damlEnumGenerator.generate(fsa, elements.filter(RosettaEnumeration), version)
		}}
		catch (Exception e) {
			LOGGER.warn("Unexpected calling standard generate for rosetta -"+e.message+" - see debug logging for more")
			LOGGER.info("Unexpected calling standard generate for rosetta", e);
		}
		finally {
			println("ending the main generate method")
			lock.releaseWriteLock
		}
	}

	override void afterGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		try {
			val models = resource.resourceSet.resources.flatMap[contents].filter(RosettaModel).toList
			val elements = models.flatMap[elements].toList
			
			val version = models.findFirst[header!==null].header.version
			damlModelObjectGenerator.generate(fsa, elements.filter(RosettaClass), elements.filter(RosettaMetaType), version)
			damlEnumGenerator.generate(fsa, elements.filter(RosettaEnumeration), version)
		
		} catch (Exception e) {
			LOGGER.warn("Unexpected calling after generate for rosetta -"+e.message+" - see debug logging for more")
			LOGGER.debug("Unexpected calling after generate for rosetta", e);
		}

	}

}
