/*
 * generated by Xtext 2.10.0
 */
package com.regnosys.rosetta.validation

import com.regnosys.rosetta.tests.RosettaInjectorProvider
import com.regnosys.rosetta.tests.util.ModelHelper
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import jakarta.inject.Inject

@ExtendWith(InjectionExtension)
@InjectWith(RosettaInjectorProvider)
class RosettaNamespaceDescriptionValidatorTest {

	@Inject extension ValidationTestHelper
	@Inject extension ModelHelper
	
	@Test
	def void testNamespaceDescription() {
		val model =
		'''
			namespace cdm.base.test : <"some description">
			version "test"
			
			enum TestEnum:
			one 
			two 
			
		'''.parseRosettaWithNoErrors
		model.assertNoErrors
	}
	
	
}
