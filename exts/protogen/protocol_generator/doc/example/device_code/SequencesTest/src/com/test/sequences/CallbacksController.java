package com.test.sequences;

import com.mdi.tools.dbg.Debug;

public class CallbacksController implements SequenceController {

	Debug _dbg = null;

	public CallbacksController(Debug dbg) {
		_dbg = dbg;
	}

	public AskToDeviceController getAskToDeviceController() {
		return new AskToDeviceImpl(_dbg);
	}

	public SimpleQuestionToServerController getSimpleQuestionToServerController() {
		return new SimpleQuestionToServerImpl(_dbg);
	}



}
