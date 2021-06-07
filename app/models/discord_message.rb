# frozen_string_literal: true

class DiscordMessage
  MESSAGE_COUNTS = 3

  def send
    if Answer.where(posted: false).count >= MESSAGE_COUNTS
      answers = Answer.find(Answer.where(posted: false).pluck(:id).sample(MESSAGE_COUNTS))
      post_message(first_message)
      answers.each do |answer|
        answer.update(posted: true) if post_message(answers_message(answer))
      end
      post_message(end_message)
    else
      post_message(no_answer_message)
    end
  end

  private

  def post_message(post)
    Discordrb::API::Channel.create_message(
      "Bot #{ENV['DISCORD_BOT_TOKEN']}",
      ENV['DISCORD_CHANNEL_ID'],
      message = post[:content],
      tts = false,
      embed = post[:embet]
    )
  end

  def create_embet(answer)
    {
      title: answer.question.body,
      description: answer.body,
      color: 0xfa8072,
      timestamp: answer.created_at,
      author: {
        name: answer.user.name,
        icon_url: answer.user.image_url
      },
      thumbnail: {
        url: answer.user.image_url
      }
    }
  end

  def answers_message(answer)
    {
      content: "<@#{answer.user.uid}>さんに聞きました！",
      embet: create_embet(answer)
    }
  end

  def first_message
    {
      content: 'こんにちは！今日もみんなに教えてもらったことを紹介するよ！',
      embet: nil
    }
  end

  def end_message
    comment = [
      '確かに〜。',
      'なるほど〜。',
      'わかります！'
    ]
    {
      content: "#{comment.sample}\n今日はみんなにこんなことも聞いてみたいな。",
      embet: daily_embet
    }
  end

  def no_answer_message
    {
      content: "こんにちは！こちらは毎日サーバーのメンバーのことを紹介するBotです！\nみんなのお話是非聞かせてください。\n今日はこんな質問はどうかな？",
      embet: daily_embet
    }
  end

  def daily_embet
    question = Question.find(Question.pluck(:id).sample)
    routes = Rails.application.routes.url_helpers
    url = routes.url_for(host: "127.0.0.1:3000", controller: :answers, action: :new, question: question.id ,only_path: false)
    {
      title: question.body,
      description: "質問に回答するには[ここ](#{url})にアクセスしてね。過去に投稿されたみんなの回答も見れるよ！"
    }
  end
end
