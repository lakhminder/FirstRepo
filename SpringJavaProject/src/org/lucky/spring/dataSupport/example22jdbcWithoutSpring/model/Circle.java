package org.lucky.spring.dataSupport.example22jdbcWithoutSpring.model;

public class Circle {

	private int id; 
	private String name;
	
	public Circle(int id, String name) {
		super();
		this.id = id;
		this.name = name;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
		
	}
	
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}
		
}
