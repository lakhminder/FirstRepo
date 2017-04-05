package org.lucky.producerConsumer;

import java.io.Serializable;
import java.util.concurrent.BlockingQueue;

public class Consumer implements Runnable{

	private BlockingQueue<? extends Serializable> queue;	
	
	public Consumer(BlockingQueue<? extends Serializable> queue) {
		super();
		this.queue = queue;
	}
	
	@Override
	public void run() {
		try {
			while(true){
				Thread.sleep(200);
			System.out.println("Consumed: " + queue.take() +" By :" + Thread.currentThread().getName());
					}
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		
		
	}

	
}
