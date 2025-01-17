package com.regnosys.rosetta.types;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Collections;
import java.util.Optional;
import java.util.stream.Collectors;

import javax.inject.Inject;

import org.eclipse.xtext.EcoreUtil2;

import com.regnosys.rosetta.RosettaExtensions;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import com.regnosys.rosetta.rosetta.RosettaBlueprint;
import com.regnosys.rosetta.rosetta.RosettaBlueprintReport;
import com.regnosys.rosetta.rosetta.RosettaCardinality;
import com.regnosys.rosetta.rosetta.RosettaExternalRegularAttribute;
import com.regnosys.rosetta.rosetta.RosettaFactory;
import com.regnosys.rosetta.rosetta.expression.ExpressionFactory;
import com.regnosys.rosetta.rosetta.expression.RosettaSymbolReference;
import com.regnosys.rosetta.rosetta.simple.Attribute;
import com.regnosys.rosetta.rosetta.simple.Data;
import com.regnosys.rosetta.rosetta.simple.Function;
import com.regnosys.rosetta.rosetta.simple.Operation;
import com.regnosys.rosetta.rosetta.simple.ShortcutDeclaration;
import com.regnosys.rosetta.rosetta.simple.SimpleFactory;
import com.regnosys.rosetta.rosetta.simple.SimplePackage;
import com.regnosys.rosetta.types.builtin.RBuiltinTypeService;
import com.regnosys.rosetta.validation.BindableType;
import com.regnosys.rosetta.validation.RosettaBlueprintTypeResolver;
import com.regnosys.rosetta.validation.RosettaBlueprintTypeResolver.BlueprintUnresolvedTypeException;
import com.regnosys.rosetta.validation.TypedBPNode;
import com.rosetta.util.DottedPath;

public class RObjectFactory {
	@Inject
	private RosettaTypeProvider rosettaTypeProvider;
	@Inject
	private CardinalityProvider cardinalityProvider;
	@Inject
	private TypeSystem typeSystem;
	@Inject
	private RosettaBlueprintTypeResolver bpTypeResolver;
	@Inject
	private RBuiltinTypeService builtins;
	@Inject
	private RosettaExtensions rosettaExtensions;

	public RFunction buildRFunction(Function function) {
		return new RFunction(DottedPath.splitOnDots(function.getModel().getName()), function.getName(),
				function.getDefinition(),
				function.getInputs().stream().map(i -> buildRAttribute(i)).collect(Collectors.toList()),
				buildRAttribute(function.getOutput()),
				RFunctionOrigin.FUNCTION,
				function.getConditions(), function.getPostConditions(),
				function.getShortcuts().stream().map(s -> buildRShortcut(s)).collect(Collectors.toList()),
				function.getOperations().stream().map(o -> buildROperation(o)).collect(Collectors.toList()),
				function.getAnnotations());
	}
	
	public RFunction buildRFunction(RosettaBlueprint rule) {
		RType inputRType, outputRType;
		boolean outputIsMulti = false;
		if (rule.isLegacy()) {
			try {
				TypedBPNode node = bpTypeResolver.buildTypeGraph(rule);
				inputRType = node.input.type.orElse(builtins.ANY);
				if (!node.repeatable) {
					outputRType = node.output.type.orElse(builtins.ANY);
				} else {
					BindableType outputTypeRef = new BindableType();
					if (rule.getModel() != null) {
						EcoreUtil2.findCrossReferences(rule.getModel(), Collections.singleton(rule), (EObject referrer, EObject referenced, EReference reference, int index) -> {
							if (!outputTypeRef.isBound()) {
								if (reference == SimplePackage.eINSTANCE.getRosettaRuleReference_ReportingRule()) {
									EObject refContainer = referrer.eContainer();
									if (refContainer instanceof Attribute) {
										outputTypeRef.type = Optional.of(rosettaTypeProvider.getRTypeOfSymbol((Attribute)refContainer));
									} else if (refContainer instanceof RosettaExternalRegularAttribute) {
										outputTypeRef.type = Optional.of(rosettaTypeProvider.getRTypeOfFeature(((RosettaExternalRegularAttribute)refContainer).getAttributeRef()));
									}
								}
							}
						});
					}
					if (!outputTypeRef.isBound() && rule.eResource() != null && rule.eResource().getResourceSet() != null) {
						ResourceSet resourceSet = rule.eResource().getResourceSet();
						outer:
						for (Resource r : resourceSet.getResources()) {
							for (EObject root : r.getContents()) {
								EcoreUtil2.findCrossReferences(root, Collections.singleton(rule), (EObject referrer, EObject referenced, EReference reference, int index) -> {
									if (!outputTypeRef.isBound()) {
										if (reference == SimplePackage.eINSTANCE.getRosettaRuleReference_ReportingRule()) {
											EObject refContainer = referrer.eContainer();
											if (refContainer instanceof Attribute) {
												outputTypeRef.type = Optional.of(rosettaTypeProvider.getRTypeOfSymbol((Attribute)refContainer));
											} else if (refContainer instanceof RosettaExternalRegularAttribute) {
												outputTypeRef.type = Optional.of(rosettaTypeProvider.getRTypeOfFeature(((RosettaExternalRegularAttribute)refContainer).getAttributeRef()));
											}
										}
									}
								});
								if (outputTypeRef.isBound()) {
									break outer;
								}
							}
						}
					}
					outputRType = outputTypeRef.type.orElse(builtins.ANY);
				}
				TypedBPNode last = node;
				if (last.cardinality[0] != null) {
					switch (last.cardinality[0]) {
						case EXPAND: {
							outputIsMulti = true;
							break;
						}
						case REDUCE: {
							outputIsMulti = false;
							break;
						}
						default:
							outputIsMulti = false;
							break;
					}
				}
				while (last.next != null) {
					last = last.next;
					if (last.cardinality[0] != null) {
						switch (last.cardinality[0]) {
							case EXPAND: {
								outputIsMulti = true;
								break;
							}
							case REDUCE: {
								outputIsMulti = false;
								break;
							}
							default:
								break;
						}
					}
				}
			} catch (BlueprintUnresolvedTypeException e) {
				throw new RuntimeException(e);
			}
		} else {
			inputRType = typeSystem.typeCallToRType(rule.getInput());
			outputRType = rosettaTypeProvider.getRType(rule.getExpression());
			outputIsMulti = cardinalityProvider.isMulti(rule.getExpression());
		}
		RAttribute outputAttribute = new RAttribute("output", null, outputRType, List.of(), outputIsMulti);
		
		return new RFunction(
				DottedPath.splitOnDots(rule.getModel().getName()),
				rule.getName(), 
				rule.getDefinition(),
				List.of(new RAttribute("input", null, inputRType, List.of(), false)),
				outputAttribute,
				RFunctionOrigin.RULE,
				List.of(),
				List.of(),
				List.of(),
				List.of(new ROperation(ROperationType.SET, outputAttribute, List.of(), rule.getExpression())),
				List.of()
			);
	}
	
	public RFunction buildRFunction(RosettaBlueprintReport report) {
		String reportName = report.getRegulatoryBody().getBody().getName()
				+ report.getRegulatoryBody().getCorpuses()
				.stream()
				.map(c -> c.getName())
				.collect(Collectors.joining(""));
		String reportDefinition = report.getRegulatoryBody().getBody().getName() + " " 
				+ report.getRegulatoryBody().getCorpuses()
				.stream()
				.map(c -> c.getName())
				.collect(Collectors.joining(" "));
		
		RType outputRtype = new RDataType(report.getReportType());
		RAttribute outputAttribute = new RAttribute("output", null, outputRtype, List.of(), false);
		
		Attribute inputAttribute = SimpleFactory.eINSTANCE.createAttribute();
		inputAttribute.setName("input");
		inputAttribute.setTypeCall(EcoreUtil2.copy(report.getInputType()));
		RosettaCardinality cardinality =  RosettaFactory.eINSTANCE.createRosettaCardinality();
		cardinality.setInf(0);
		cardinality.setSup(1);
		inputAttribute.setCard(cardinality);
		
		Map<Attribute, RosettaBlueprint> attributeToRuleMap = rosettaExtensions.getAllReportingRules(report, false, false)
			.entrySet()
			.stream()
			.collect(Collectors.toMap(e -> e.getKey().getAttr(), e -> e.getValue()));
		
		
		List<ROperation> operations = generateReportOperations(report.getReportType(), attributeToRuleMap, inputAttribute, List.of(outputAttribute));
		
		return new RFunction(
			DottedPath.splitOnDots(report.getModel().getName()),
			reportName,
			reportDefinition,
			List.of(buildRAttribute(inputAttribute)),
			outputAttribute,
			RFunctionOrigin.REPORT,
			List.of(),
			List.of(),
			List.of(),
			operations,
			List.of()
		);
	}
	
	private List<ROperation> generateReportOperations(Data reportDataType, Map<Attribute, RosettaBlueprint> attributeToRuleMap, Attribute inputAttribute, List<RAttribute> assignPath) {
		Iterable<Attribute> attributes = rosettaExtensions.getAllAttributes(reportDataType);
		List<ROperation> operations = new ArrayList<>();
		
		for (Attribute attribute : attributes) {
			RAttribute rAttribute = buildRAttribute(attribute);
			List<RAttribute> newAssignPath = new ArrayList<>(assignPath);
			newAssignPath.add(rAttribute);
			if (attributeToRuleMap.containsKey(attribute)) {
				operations.add(generateOperationForRuleReference(inputAttribute, attributeToRuleMap.get(attribute), newAssignPath));
				continue;
			}
			if (rAttribute.getRType() instanceof RDataType) {
				RDataType rData = (RDataType) rAttribute.getRType();
				Data data = rData.getData();		
				operations.addAll(generateReportOperations(data, attributeToRuleMap, inputAttribute, newAssignPath));
			}
		}
		return operations;
	}
	
	private ROperation generateOperationForRuleReference(Attribute inputAttribute, RosettaBlueprint rule, List<RAttribute> assignPath) {
		RAttribute pathHead = assignPath.get(0);
		List<RAttribute> pathTail = assignPath.subList(1, assignPath.size());
		
		RosettaSymbolReference inputAttributeSymbolRef = ExpressionFactory.eINSTANCE.createRosettaSymbolReference();
		inputAttributeSymbolRef.setSymbol(inputAttribute);
		
		RosettaSymbolReference symbolRef = ExpressionFactory.eINSTANCE.createRosettaSymbolReference();
		symbolRef.setSymbol(rule);
		symbolRef.setExplicitArguments(true);
		symbolRef.getArgs().add(inputAttributeSymbolRef);
		
		return new ROperation(ROperationType.SET, pathHead, pathTail, symbolRef);
	}

	public RAttribute buildRAttribute(Attribute attribute) {
		RType rType = this.rosettaTypeProvider.getRTypeOfSymbol(attribute);
		List<RAttribute> metaAnnotations = attribute.getAnnotations().stream()
				.filter(a -> a.getAnnotation().getName().equals("metadata")).map(a -> buildRAttribute(a.getAttribute()))
				.collect(Collectors.toList());

		return new RAttribute(attribute.getName(), attribute.getDefinition(), rType, metaAnnotations,
				cardinalityProvider.isSymbolMulti(attribute));

	}

	public RShortcut buildRShortcut(ShortcutDeclaration shortcut) {
		return new RShortcut(shortcut.getName(), shortcut.getDefinition(), shortcut.getExpression());

	}

	public ROperation buildROperation(Operation operation) {
		ROperationType operationType = operation.isAdd() ? ROperationType.ADD : ROperationType.SET;
		RAssignedRoot pathHead;

		if (operation.getAssignRoot() instanceof Attribute) {
			pathHead = buildRAttribute((Attribute) operation.getAssignRoot());
		} else {
			pathHead = buildRShortcut((ShortcutDeclaration) operation.getAssignRoot());
		}

		List<RAttribute> pathTail = operation.pathAsSegmentList().stream().map(s -> buildRAttribute(s.getAttribute()))
				.collect(Collectors.toList());

		return new ROperation(operationType, pathHead, pathTail, operation.getExpression());
	}

}
