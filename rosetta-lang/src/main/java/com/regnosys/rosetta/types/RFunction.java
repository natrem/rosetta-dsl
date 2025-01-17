package com.regnosys.rosetta.types;

import java.util.List;
import java.util.Objects;
import com.regnosys.rosetta.rosetta.simple.AnnotationRef;
import com.regnosys.rosetta.rosetta.simple.Condition;
import com.rosetta.model.lib.ModelSymbol.AbstractModelSymbol;
import com.rosetta.util.DottedPath;

public class RFunction extends AbstractModelSymbol {
	private String definition;
	private List<RAttribute> inputs;
	private RAttribute output;
	private RFunctionOrigin origin;
	private List<Condition> preConditions;
	private List<Condition> postConditions;
	private List<RShortcut> shortcuts;
	private List<ROperation> operations;
	private List<AnnotationRef> annotations;
	
	public RFunction(DottedPath namespace, String name, String definition, List<RAttribute> inputs,
			RAttribute output, RFunctionOrigin origin, List<Condition> preConditions, List<Condition> postConditions,
			List<RShortcut> shortcuts, List<ROperation> operations, List<AnnotationRef> annotations) {
		super(namespace, name);
		this.definition = definition;
		this.inputs = inputs;
		this.output = output;
		this.origin = origin;
		this.preConditions = preConditions;
		this.postConditions = postConditions;
		this.shortcuts = shortcuts;
		this.operations = operations;
		this.annotations = annotations;
	}

	public String getDefinition() {
		return definition;
	}

	public List<RAttribute> getInputs() {
		return inputs;
	}

	public RAttribute getOutput() {
		return output;
	}

	public RFunctionOrigin getOrigin() {
		return origin;
	}

	public List<Condition> getPreConditions() {
		return preConditions;
	}

	public List<Condition> getPostConditions() {
		return postConditions;
	}

	public List<RShortcut> getShortcuts() {
		return shortcuts;
	}

	public List<ROperation> getOperations() {
		return operations;
	}

	public List<AnnotationRef> getAnnotations() {
		return annotations;
	}

	@Override
	public int hashCode() {
		return Objects.hash(annotations, definition, inputs, getSymbolId(), operations, origin, output,
				postConditions, preConditions, shortcuts);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		RFunction other = (RFunction) obj;
		return Objects.equals(annotations, other.annotations) && Objects.equals(definition, other.definition)
				&& Objects.equals(inputs, other.inputs) && Objects.equals(getSymbolId(), other.getSymbolId())
				&& Objects.equals(operations, other.operations)
				&& origin == other.origin && Objects.equals(output, other.output)
				&& Objects.equals(postConditions, other.postConditions)
				&& Objects.equals(preConditions, other.preConditions) && Objects.equals(shortcuts, other.shortcuts);
	}
}
