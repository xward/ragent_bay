module AskToDeviceCallbacks

  # message is an object of class MessageClass
  def self.immediate_answer_from_device(message)
    answer = message.content
    user_api.mdi.tools.log.info("Received a immediate device answer! #{answer.content}")
  end

  def self.more_information_needed(message)
    answer = message.content
    user_api.mdi.tools.log.info("The device wants to know more before answering my question! #{answer.query}")
    response = user_api.mdi.tools.protogen.protogen_apis::Protogen::Messages::AnswerToDevice.new
    response.content = "I won't give you more!"
    # 42/0 # Uncomment this if you want to test the feature "immediately inform the device of a server-side error"
    response
  end

  def self.final_device_answer(message)
    answer = message.content
    user_api.mdi.tools.log.info("The device finally answered my request! #{answer.content}")
  end
end

module SimpleQuestionToServerCallbacks

  def self.question_from_device(message)
    question = message.content
    user_api.mdi.tools.log.info("The device asked a question! #{question.query}")
    response = user_api.mdi.tools.protogen.protogen_apis::Protogen::Messages::AnswerToDevice.new
    response.content = "I don't want to answer that :-x"
    response
  end

end