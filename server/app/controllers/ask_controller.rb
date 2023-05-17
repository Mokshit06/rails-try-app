require "resemble"
require "rover-df"

$client ||= OpenAI::Client.new(access_token: Rails.application.credentials.openai_access_token)

Resemble.api_key = Rails.application.credentials.resemble_api_key

COMPLETIONS_MODEL ||= "text-davinci-003"

MODEL_NAME ||= "curie"

DOC_EMBEDDINGS_MODEL ||= "text-search-#{MODEL_NAME}-doc-001"
QUERY_EMBEDDINGS_MODEL ||= "text-search-#{MODEL_NAME}-query-001"

MAX_SECTION_LEN ||= 500
SEPARATOR ||= "\n* "
SEPARATOR_LEN ||= 3

PROJECT_UUID ||= "7b950242"
VOICE_UUID ||= "e3dcb733"

def load_embeddings(fname)
  df = Rover.read_csv(fname)
  max_dim = df.keys.map { |c| c.to_i }.drop(1).max()

  embeddings = df.each_row.map do |row|
    [row["title"], (0..(max_dim + 1)).map { |i| row[i.to_s()] }]
  end

  return embeddings
end

def vector_similarity(x, y)
  dot_product = x.zip(y).map { |a, b| a * b }.sum()
  dot_product.to_f()
end

def order_document_sections_by_query_similarity(query, contexts)
  query_embedding = get_query_embedding(query)

  similarities = contexts.map { |doc_index, doc_embedding| [vector_similarity(query_embedding, doc_embedding), doc_index] }.sort_by { |dot, i| dot }.reverse

  return similarities
end

def get_embedding(text, model)
  result = $client.embeddings(
    parameters: {
      model: model,
      input: text,
    },
  )

  return result["data"][0]["embedding"]
end

def construct_prompt(question, context_embeddings, df)
  most_relevant_document_sections = order_document_sections_by_query_similarity(
    question, context_embeddings
  )

  chosen_sections = []
  chosen_sections_len = 0
  chosen_sections_indexes = []

  most_relevant_document_sections.each do |_, section_index|
    document_section = df[df["title"] == section_index][0]
    chosen_sections_len += document_section["tokens"][0] + SEPARATOR_LEN

    if chosen_sections_len > MAX_SECTION_LEN
      space_left = MAX_SECTION_LEN - chosen_sections_len - SEPARATOR.length
      chosen_sections.append(
        SEPARATOR + document_section["content"][0][..space_left]
      )
      chosen_sections_indexes.append(section_index.to_s())
      break
    end

    chosen_sections.append(SEPARATOR + document_section["content"][0])
    chosen_sections_indexes.append(section_index.to_s())
  end

  header = "" "Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n" ""

  questions = ["\n\n\nQ: How to choose what business to start?\n\nA: First off don't be in a rush. Look around you, see what problems you or other people are facing, and solve one of these problems if you see some overlap with your passions or skills. Or, even if you don't see an overlap, imagine how you would solve that problem anyway. Start super, super small.", "\n\n\nQ: Q: Should we start the business on the side first or should we put full effort right from the start?\n\nA:   Always on the side. Things start small and get bigger from there, and I don't know if I would ever “fully” commit to something unless I had some semblance of customer traction. Like with this product I'm working on now!", "\n\n\nQ: Should we sell first than build or the other way around?\n\nA: I would recommend building first. Building will teach you a lot, and too many people use “sales” as an excuse to never learn essential skills like building. You can't sell a house you can't build!", "\n\n\nQ: Andrew Chen has a book on this so maybe touché, but how should founders think about the cold start problem? Businesses are hard to start, and even harder to sustain but the latter is somewhat defined and structured, whereas the former is the vast unknown. Not sure if it's worthy, but this is something I have personally struggled with\n\nA: Hey, this is about my book, not his! I would solve the problem from a single player perspective first. For example, Gumroad is useful to a creator looking to sell something even if no one is currently using the platform. Usage helps, but it's not necessary.", "\n\n\nQ: What is one business that you think is ripe for a minimalist Entrepreneur innovation that isn't currently being pursued by your community?\n\nA: I would move to a place outside of a big city and watch how broken, slow, and non-automated most things are. And of course the big categories like housing, transportation, toys, healthcare, supply chain, food, and more, are constantly being upturned. Go to an industry conference and it's all they talk about! Any industry…", "\n\n\nQ: How can you tell if your pricing is right? If you are leaving money on the table\n\nA: I would work backwards from the kind of success you want, how many customers you think you can reasonably get to within a few years, and then reverse engineer how much it should be priced to make that work.", "\n\n\nQ: Why is the name of your book 'the minimalist entrepreneur' \n\nA: I think more people should start businesses, and was hoping that making it feel more “minimal” would make it feel more achievable and lead more people to starting-the hardest step.", "\n\n\nQ: How long it takes to write TME\n\nA: About 500 hours over the course of a year or two, including book proposal and outline.", "\n\n\nQ: What is the best way to distribute surveys to test my product idea\n\nA: I use Google Forms and my email list / Twitter account. Works great and is 100% free.", "\n\n\nQ: How do you know, when to quit\n\nA: When I'm bored, no longer learning, not earning enough, getting physically unhealthy, etc… loads of reasons. I think the default should be to “quit” and work on something new. Few things are worth holding your attention for a long period of time."]

  return header + chosen_sections.join("") + questions.join("") + "\n\n\nQ: " + question + "\n\nA: ", chosen_sections.join("")
end

def answer_query_with_context(
  query,
  df,
  document_embeddings
)
  prompt, context = construct_prompt(
    query,
    document_embeddings,
    df
  )

  response = $client.completions(
    parameters: {
      model: COMPLETIONS_MODEL,
      prompt: prompt,
      max_tokens: 150,
      temperature: 0.0,
    },
  )

  return response["choices"][0]["text"].strip, context
end

def get_doc_embedding(text)
  return get_embedding(text, DOC_EMBEDDING_MODEL)
end

def get_query_embedding(text)
  return get_embedding(text, QUERY_EMBEDDINGS_MODEL)
end

class AskController < ApplicationController
  def index
    ques = params[:question] || ""

    unless ques.end_with?("?")
      ques += "?"
    end

    prev_ques = Question.find_by(question: ques)
    audio_src_url = prev_ques&.audio_src_url

    if audio_src_url
      puts "previously asked and answered: #{prev_ques.answer} ( #{audio_src_url} )"
      prev_ques.ask_count += 1
      prev_ques.save()

      render json: {
        question: prev_ques.question,
        answer: prev_ques.answer,
        audio_src_url: audio_src_url,
        id: prev_ques.id,
      }
      return
    end

    df = Rover.read_csv("book.pdf.pages.csv")
    doc_embeddings = load_embeddings("book.pdf.embeddings.csv")
    answer, context = answer_query_with_context(
      ques, df, doc_embeddings
    )

    response = Resemble::V2::Clip.create_sync(
      PROJECT_UUID,
      VOICE_UUID,
      answer,
      title: nil,
      sample_rate: nil,
      output_format: nil,
      precision: nil,
      include_timestamps: nil,
      is_public: nil,
      is_archived: nil,
      raw: nil,
    )

    question = Question.create(
      question: ques,
      answer: answer,
      context: context,
      audio_src_url: response["item"] && response["item"]["audio_src"],
    )

    render json: {
      question: question.question,
      answer: answer,
      audio_src_url: question.audio_src_url,
      id: question.id,
    }
  end

  def question
    ques = Question.find_by(id: params[:id])

    render json: {
      id: ques.id,
      default_question: ques.question,
      answer: ques.answer,
      audio_src_url: ques.audio_src_url,
    }
  end
end
