# frozen_string_literal: true
module Flickrage
  module Worker
    autoload :Base,     'flickrage/worker/base'
    autoload :Resize,   'flickrage/worker/resize'
    autoload :Download, 'flickrage/worker/download'
    autoload :Search,   'flickrage/worker/search'
    autoload :Compose,  'flickrage/worker/compose'
  end
end
