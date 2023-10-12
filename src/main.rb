require_relative './models/image_processing.rb'

if __FILE__ == $0
  images = [
    ImageProcessing.new('./assets/', 'coins', 'png'),
    ImageProcessing.new('./assets/', 'dog', 'png'),
    ImageProcessing.new('./assets/', 'lena', 'jpg'),
    ImageProcessing.new('./assets/', 'ufrn', 'png'),
  ]

  images.each(&:processes_edges)
end