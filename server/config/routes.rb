Rails.application.routes.draw do
  post "/ask", to: "ask#index"
  get "/question/:id", to: "ask#question"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  # get "/ask", to: "ask#index"
  # get "/question/:id", to: "question#index", constraints: {id:/^\d/}
end
