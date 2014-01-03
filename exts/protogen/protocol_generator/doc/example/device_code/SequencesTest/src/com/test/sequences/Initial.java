package com.test.sequences;

import com.mdi.tools.dbg.Debug;
import com.test.sequences.Codec.UnknownMessage;
import com.test.sequences.MDIMessages.QuestionToServer;

public class Initial implements com.mdi.tools.cpn.Initial {

	private static Initial _instance = new Initial();

	public void shutdown() {
		// TODO Auto-generated method stub

	}

	public void start() {
		Debug dbg = Component.getInstance().getDebug();
		dbg.init(0);
		Dispatcher dispatcher = new Dispatcher("com.mdi.services.sequences_test",
				Component.getInstance().getMessageGate(),
				Component.getInstance().getBinaryGate(),
				new CallbacksController(dbg),
				dbg);
		dbg.print("protogen demo 30s sleep");
		try {
			Thread.sleep(30000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		MDIMessages.QuestionToServer msg = new QuestionToServer();
		StringBuilder builder = new StringBuilder();
		for(int i = 0; i < 10; i++) {
			builder.append("(");
			builder.append(i);
			builder.append(") do you copy?  ");
		}
		msg.query = builder.toString();
		try {
			while(true) {
				dispatcher.startSimpleQuestionToServerSequence(msg);
				Thread.sleep(30000);
			}
		} catch (UnknownMessage e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}

	}

	private Initial() {
		// TODO Auto-generated method stub
	}

	static Initial getInstance() {
		return _instance;
	}

}
