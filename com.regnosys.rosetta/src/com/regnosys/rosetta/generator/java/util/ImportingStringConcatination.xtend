package com.regnosys.rosetta.generator.java.util

import java.lang.reflect.Method
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend2.lib.StringConcatenation
import org.eclipse.xtext.naming.QualifiedName

class ImportingStringConcatination extends StringConcatenation {
	@Accessors(PUBLIC_GETTER)
	Set<String> imports = newHashSet
	Set<String> staticImports = newHashSet

	def dispatch protected String getStringRepresentation(Object object) {
		super.getStringRepresentation(object)
	}

	def dispatch protected String getStringRepresentation(Class<?> object) {
		addImport(object.name, object.isEnum && object.isMemberClass)
		return object.simpleName
	}
	
	def dispatch protected String getStringRepresentation(Method object) {
		addStaticImport(object)
		return object.name
	}

	def dispatch protected String getStringRepresentation(JavaType object) {
		addImport(object.name, false)
		return object.simpleName
	}
	
	def private addStaticImport(Method method) {
		val qName = method.declaringClass.name
		
		val qualified = QualifiedName.create(qName.split('\\.'))
		val target = qualified.lastSegment
		
		if (target.contains('$')) {
			val toImport = qualified.skipLast(1).append(target.split('\\$').head)
			staticImports.add(toImport.toString + '.' + method.name)	
		} else {
			staticImports.add(qName  + '.' + method.name)	
		}
	}

	def private addImport(String qName, boolean qualifyMemberClass) {
		val qualified = QualifiedName.create(qName.split('\\.'))
		val target = qualified.lastSegment
		if (target.contains('$')) {
			if (!qualifyMemberClass) {
				val toImport = qualified.skipLast(1).append(target.split('\\$').head)
				imports.add(toImport.toString)
			} else
				imports.add(qName.replaceAll('\\$', '.'))

		} else {
			imports.add(qName)
		}
	}
	
	def getImports() {
		imports.sortBy[it]
	}
	
	def getStaticImports() {
		staticImports.sortBy[it]
	}
}