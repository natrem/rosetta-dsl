
package com.regnosys.rosetta.generator.java.object

import com.google.inject.Inject
import com.regnosys.rosetta.RosettaExtensions
import com.regnosys.rosetta.generator.java.RosettaJavaPackages
import com.regnosys.rosetta.generator.java.util.ImportManagerExtension
import com.regnosys.rosetta.generator.java.util.JavaNames
import com.regnosys.rosetta.generator.object.ExpandedAttribute
import com.regnosys.rosetta.generator.object.ExpandedSynonym
import com.regnosys.rosetta.rosetta.RosettaClassSynonym
import com.regnosys.rosetta.rosetta.RosettaSynonymBase
import com.regnosys.rosetta.rosetta.simple.Data
import com.rosetta.model.lib.RosettaModelObject
import com.rosetta.model.lib.annotations.RosettaClass
import com.rosetta.model.lib.annotations.RosettaSynonym
import com.rosetta.model.lib.meta.RosettaMetaData
import java.util.List
import java.util.Objects
import java.util.Optional
import java.util.stream.Collectors
import org.eclipse.xtend2.lib.StringConcatenationClient
import org.eclipse.xtext.generator.IFileSystemAccess2

import static com.regnosys.rosetta.generator.java.util.ModelGeneratorUtil.*

import static extension com.regnosys.rosetta.generator.util.RosettaAttributeExtensions.*

class DataGenerator {
	@Inject extension RosettaExtensions
	@Inject extension ModelObjectBoilerPlate
	@Inject extension ModelObjectBuilderGenerator
	@Inject extension ImportManagerExtension
	
	@Inject JavaNames.Factory factory

	def generate(RosettaJavaPackages packages, IFileSystemAccess2 fsa, Data data, String version) {
		fsa.generateFile(packages.model.directoryName + '/' + data.name + '.java',
			generateRosettaClass(packages, data, version))
			
		fsa.generateFile(packages.model.directoryName + '/' + data.name + '.java',
			generateRosettaClass(packages, data, version))
	}

	
	private def hasSynonymPath(ExpandedSynonym synonym) {
		synonym !== null && synonym.values.exists[path!==null]
	}
	
	private def hasSynonymPath(RosettaSynonymBase p) {
		return hasSynonymPath(p.toRosettaExpandedSynonym)
	}
	
	private def generateRosettaClass(RosettaJavaPackages packages, Data d, String version) {
		val classBody = tracImports(d.classBody(factory.create(packages), version))
		'''
			package «packages.model.packageName»;
			
			«FOR imp : classBody.imports»
				import «imp»;
			«ENDFOR»
«««			TODO fix imports below. See com.regnosys.rosetta.generator.java.object.ModelObjectBuilderGenerator.process(List<ExpandedAttribute>, boolean)

			import com.rosetta.model.lib.path.RosettaPath;
			import com.rosetta.model.lib.process.BuilderProcessor;
			import com.rosetta.model.lib.process.Processor;

			«FOR imp : classBody.staticImports»
				import static «imp»;
			«ENDFOR»
			
			«classBody.toString»
		'''
	}

	def private StringConcatenationClient classBody(Data d, JavaNames names, String version) '''
		«javadocWithVersion(d.definition, version)»
		@«RosettaClass»
		«contributeClassSynonyms(d.synonyms)»
		public class «d.name» extends «IF d.hasSuperType»«d.superType?.name»«ELSE»«RosettaModelObject»«ENDIF» {
			«d.rosettaClass(names)»

			«d.staticBuilderMethod»

			«d.builderClass(names)»

			«d.boilerPlate»
		}
	'''
	
	private def StringConcatenationClient rosettaClass(Data c, JavaNames names) {
	val expandedAttributes = c.expandedAttributes
	 '''
		«FOR attribute : expandedAttributes»
			private final «attribute.toJavaType(names)» «attribute.name»;
		«ENDFOR»
		«val metaType = names.packages.meta.javaType(c.name+'Meta')»
		private static «metaType» metaData = new «metaType»();

		«c.name»(«c.builderName» builder) {
			«IF c.hasSuperType»
				super(builder);
			«ENDIF»
			«FOR attribute : expandedAttributes»
				this.«attribute.name» = «attribute.attributeFromBuilder»;
			«ENDFOR»
		}

		«FOR attribute : expandedAttributes»
			«javadoc(attribute.definition)»
			«contributeSynonyms(attribute.synonyms)»
			public final «attribute.toJavaType(names)» get«attribute.name.toFirstUpper»() {
				return «attribute.name»;
			}
			
		«ENDFOR»
		
		@Override
		public «RosettaMetaData»<? extends «c.name»> metaData() {
			return metaData;
		} 

«««		«IF !c.isAbstract»
		public «c.builderName» toBuilder() {
			«c.builderName» builder = new «c.builderName»();
			«FOR attribute : c.getAllSuperTypes.map[it.expandedAttributes].flatten»
				«IF attribute.cardinalityIsListValue»
					«Optional.importMethod("ofNullable")»(get«attribute.name.toFirstUpper»()).ifPresent(«attribute.name» -> «attribute.name».forEach(builder::add«attribute.name.toFirstUpper»));
				«ELSE»
					«Optional.importMethod("ofNullable")»(get«attribute.name.toFirstUpper»()).ifPresent(builder::set«attribute.name.toFirstUpper»);
				«ENDIF»
			«ENDFOR»
			return builder;
		}
«««		«ELSE»
«««			public abstract «c.builderName» toBuilder();
«««		«ENDIF»
	'''
	}
	
	private def StringConcatenationClient toJavaType(ExpandedAttribute attribute, JavaNames names) {
		if (attribute.isMultiple) '''«List»<«attribute.toJavaTypeSingle(names)»>''' 
		else attribute.toJavaTypeSingle(names);
	}

	private def StringConcatenationClient toJavaTypeSingle(ExpandedAttribute attribute, JavaNames names) {
		if (!attribute.hasMetas)
			names.toJavaQualifiedType(attribute.type)
		else if (attribute.refIndex >= 0) {
			if (attribute.isRosettaClassOrData)
				'''«names.packages.metaField.javaType('ReferenceWithMeta'+attribute.typeName.toFirstUpper)»'''
			else
				'''«names.packages.metaField.javaType('BasicReferenceWithMeta'+attribute.typeName.toFirstUpper)»'''
		} else
			'''«names.packages.metaField.javaType('FieldWithMeta'+attribute.typeName.toFirstUpper)»'''
	}
	
	private def StringConcatenationClient contributeClassSynonyms(List<RosettaClassSynonym> synonyms) '''		
		«FOR synonym : synonyms.filter[value!==null] »
			«val path = if (hasSynonymPath(synonym)) ''', path="«synonym.value.path»" ''' else ''»
			«val maps = if (synonym.value.maps > 0) ''', maps=«synonym.value.maps»''' else ''»
			
			«FOR source : synonym.sources»
				@«RosettaSynonym»(value="«synonym.value.name»", source="«source.getName»"«path»«maps»)
			«ENDFOR»
		«ENDFOR»
	'''
	
	private def StringConcatenationClient contributeSynonyms(List<ExpandedSynonym> synonyms) '''		
		«FOR synonym : synonyms »
			«val maps = if (synonym.values.exists[v|v.maps>1]) ''', maps=«synonym.values.map[maps].join(",")»''' else ''»
			«FOR source : synonym.sources»
				«IF !synonym.hasSynonymPath»
					@«RosettaSynonym»(value="«synonym.values.map[name].join(",")»", source="«source.getName»"«maps»)
				«ELSE»
					«FOR value : synonym.values»
						@«RosettaSynonym»(value="«value.name»", source="«source.getName»", path="«value.path»"«maps»)
					«ENDFOR»
				«ENDIF»
			«ENDFOR»
		«ENDFOR»
	'''
	

	private def staticBuilderMethod(Data c) '''
		public static «builderName(c)» builder() {
			return new «builderName(c)»();
		}
	'''

	private def StringConcatenationClient attributeFromBuilder(ExpandedAttribute attribute) {
		if(attribute.isRosettaClassOrData || attribute.hasMetas) {
			'''ofNullable(builder.get«attribute.name.toFirstUpper»()).map(«attribute.buildRosettaObject»).orElse(null)'''
		} else {
			'''builder.get«attribute.name.toFirstUpper»()'''
		} 
	}
	
	private def StringConcatenationClient buildRosettaObject(ExpandedAttribute attribute) {
		if(attribute.cardinalityIsListValue) {
			'''list -> list.stream().filter(«Objects»::nonNull).map(f->f.build()).filter(«Objects»::nonNull).collect(«Collectors».toList())'''
		} else {
			'''f->f.build()'''
		}
	}
	
}