package com.test.sequences;

import com.mdi.tools.dbg.Debug;
import com.test.sequences.MDIMessages.AnswerToDevice;

public class SimpleQuestionToServerImpl implements
		SimpleQuestionToServerController {

	private Debug _dbg;

	public SimpleQuestionToServerImpl(Debug dbg) {
		_dbg = dbg;
	}

	public void answerFromServer(AnswerToDevice msg) {
		_dbg.print("The server answered my query! " + msg.content);

	}

}
