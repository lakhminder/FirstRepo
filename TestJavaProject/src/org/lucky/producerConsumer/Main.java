package org.lucky.producerConsumer;

import java.io.Serializable;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.RejectedExecutionHandler;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class Main {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		//BlockingQueue<? super Serializable> queue = new ArrayBlockingQueue<String>(5); // not working generics
		BlockingQueue<String> queue = new ArrayBlockingQueue<String>(5);
		
		Thread singleProducer = new Thread(new Producer(queue));
		
		//BlockingQueue<Runnable> threadExecutorQueue = new ArrayBlockingQueue<Runnable>(1);
		
		ThreadPoolExecutor executor = new ThreadPoolExecutor(2, 2, 3, TimeUnit.MILLISECONDS, new ArrayBlockingQueue<Runnable>(1), new ThreadFactory() {
			int counter = 0;
			@Override
			public Thread newThread(Runnable r) {
				// TODO Auto-generated method stub
				return new Thread(r,"ConsumerThread" + counter++);
			}
		}, new RejectedExecutionHandler() {
			
			@Override
			public void rejectedExecution(Runnable r, ThreadPoolExecutor poolExecutor) {
				try {
					System.out.println("Rejected:" + r);
					poolExecutor.getQueue().put(r);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				
			}
		}) ;
		
		singleProducer.start();
		executor.execute(new Consumer(queue));
		executor.execute(new Consumer(queue));
		executor.shutdown();
		//Executor consumer = Executors.newFixedThreadPool
	}

}
