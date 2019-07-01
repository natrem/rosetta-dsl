/*
 * generated by Xtext 2.10.0
 */
package com.regnosys.rosetta.ui

import com.regnosys.rosetta.ide.highlight.RosettaHighlightingCalculator
import com.regnosys.rosetta.ui.highlight.RosettaHighlightingConfiguration
import com.regnosys.rosetta.ui.validation.RosettaUIValidator
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.service.SingletonBinding
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfiguration
import org.eclipse.xtext.validation.AbstractDeclarativeValidator
import org.eclipse.xtext.ui.editor.hover.IEObjectHoverProvider
import com.regnosys.rosetta.ui.hover.RosettaHoverProvider

/**
 * Use this class to register components to be used within the Eclipse IDE.
 */
@FinalFieldsConstructor
class RosettaUiModule extends AbstractRosettaUiModule {
	
	def Class<? extends IHighlightingConfiguration> bindIHighlightingConfiguration() {
		RosettaHighlightingConfiguration
	}
	
	def Class<? extends ISemanticHighlightingCalculator> bindISemanticHighlightingCalculator() {
		RosettaHighlightingCalculator
	}

	@SingletonBinding(eager=true)
	def Class<? extends AbstractDeclarativeValidator> bindUIValidator() {
		return RosettaUIValidator
	}
	
	def Class<? extends IEObjectHoverProvider> bindIEObjectHoverProvider() {
		RosettaHoverProvider
	}
	
}
