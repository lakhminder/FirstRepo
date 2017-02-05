package org.lucky.lambdas.eg2LambdaAsInterface;


/**
 * @FunctionalInterface is optional but strongly recommended as to mark for other developer
 * as it can not allow to add any other abstract method.
 * 
 * For backward compatibility now interface can have default methods as well i.e method implementations
 * 
 * So for Lambda/Functional interface are ones which has only one abstract method
 * 
 *
 */
@FunctionalInterface
public interface Greeting {
	
	public void perform();

}
