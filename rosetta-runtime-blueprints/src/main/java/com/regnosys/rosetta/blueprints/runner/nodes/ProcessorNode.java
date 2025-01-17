package com.regnosys.rosetta.blueprints.runner.nodes;

import com.regnosys.rosetta.blueprints.runner.data.GroupableData;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Collection;
import java.util.Collections;
import java.util.Optional;

public interface ProcessorNode<I,O, K> extends Node<I, O, K, K>{
    Logger LOGGER = LoggerFactory.getLogger(ProcessorNode.class);
    
	<T extends I, K2 extends K> Optional<GroupableData<O, K2>> process(GroupableData<T, K2> input);
	
	default Collection<GroupableData<? extends O, ? extends K>> terminate() {
	    LOGGER.trace("calling teminate on "+getName()+" instance of "+this.getClass());
		return Collections.emptyList();
	}
}
