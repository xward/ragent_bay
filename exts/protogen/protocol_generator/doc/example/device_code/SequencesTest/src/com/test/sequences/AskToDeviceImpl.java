package com.test.sequences;

import com.mdi.tools.dbg.Debug;
import com.test.sequences.MDIMessages.AbstractMessage;
import com.test.sequences.MDIMessages.AnswerToDevice;
import com.test.sequences.MDIMessages.AnswerToServer;
import com.test.sequences.MDIMessages.QuestionToDevice;
import com.test.sequences.MDIMessages.QuestionToServer;
import com.test.sequences.ProtogenMessages.ServerError;

public class AskToDeviceImpl implements AskToDeviceController {

	private Debug _dbg;

	public AskToDeviceImpl(Debug dbg) {
		_dbg = dbg;
	}

	public AbstractMessage QuestionFromServerCallback(QuestionToDevice msg) {
		_dbg.print("Received a question from the server! " + msg.query);
		QuestionToServer answer = new QuestionToServer();
		answer.query = "I don't know! Need more info";
		return answer;
	}

	public AbstractMessage moreInformationFromServer(AnswerToDevice msg) {
		_dbg.print("Received more information from the server! " + msg.content);
		AnswerToServer answer = new AnswerToServer();
		answer.content = "I still don't know :-(";
		return answer;
	}

	public void serverErrorCallback(ServerError msg) {
		_dbg.print("Oups! the server crashed!" + msg.getInfoMessage());

	}

	public void serverErrorCallback2(ServerError msg) {
		_dbg.print("Oups! the server crashed!" + msg.getInfoMessage());
	}

	public void aborted() {
		_dbg.print("Oups! the sequence aborted !");
	}

}
