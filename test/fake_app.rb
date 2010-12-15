require 'sinatra'

class FakeApp < Sinatra::Base
  get "/" do
    "foo"
  end
end
