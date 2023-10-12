require 'mini_magick'

MiniMagick.configure { |config| config.tmpdir='./tmp' }

class ImageProcessing
  attr_accessor :file_input, :file_output,  :folder_path, :image_name, 
                :image_extension, :image, :width, :height, :pixels, :Gx, :Gy, :G
  
  # Initializes an instance of the ImageProcessing class.
  #
  # @param folder_path [String] The folder path where the input image is located.
  # @param image_name [String] The name of the input image file (without extension).
  # @param image_extension [String] The extension of the input image file.
  def initialize(folder_path, image_name, image_extension)
    @file_input      = File.join(folder_path, "#{image_name}.#{image_extension}")
    @file_output     = File.join(folder_path, "#{image_name}_output.#{image_extension}")

    @folder_path     = folder_path
    @image_name      = image_name
    @image_extension = image_extension
    
    @image           = MiniMagick::Image.open(@file_input)
    
    @width           = @image.width
    @height          = @image.height
    @pixels          = @image.get_pixels

    @Gx              = Array.new(@height){Array.new(@width, 0)}
    @Gy              = Array.new(@height){Array.new(@width, 0)}
    @G               = Array.new(@height){Array.new(@width){Array.new(3, 0)}}
  end

  # Performs edge detection and reliefs processing using threads.
  def processes_edges
    thread_x = Thread.new { calculate_Gx! }
    thread_y = Thread.new { calculate_Gy! }

    thread_x.join
    thread_y.join

    build_output_image
  end

  # Builds the output image after processing and saves it to a file.
  def build_output_image
    calculate_G!

    blob = @G.flatten.pack("C*")
    output_image = MiniMagick::Image.import_pixels(blob, @width, @height, 8, "rgb", "jpg")
    output_image.write(@file_output)

    clear_tmp_folder!
  end

  private

  # Calculates the final output image G.
  def calculate_G!
    i, j = 0, 0
    (i..(@height - 1)).each do |i|
      (j..(@width - 1)).each do |j|
        @G[i][j] = @Gx[i][j] + @Gy[i][j]
        @G[i][j] = 255 if @G[i][j] > 255

        @G[i][j] = Array.new(3, @G[i][j])
      end
    end
  end

  # Calculates the edge image Gx.
  def calculate_Gx!
    i, j = 1, 1
    (i..(@height - 2)).each do |i|
      (j..(@width - 2)).each do |j|
        @Gx[i][j] = (bw(@pixels[i+1][j-1]) + bw(@pixels[i+1][j]) + bw(@pixels[i+1][j+1])) - (bw(@pixels[i-1][j-1]) + bw(@pixels[i-1][j]) + bw(@pixels[i-1][j+1]))

        if @Gx[i][j].to_i < 0
          @Gx[i][j] = 0
        elsif @Gx[i][j].to_i > 255
          @Gx[i][j] = 255
        end
      end
    end
  end

  # Calculates the edge image Gy.
  def calculate_Gy!
    i, j = 0, 0
    (i..(@height - 2)).each do |i|
      (j..(@width - 2)).each do |j|
        @Gy[i][j] = (bw(@pixels[i-1][j+1]) + bw(@pixels[i][j+1]) + bw(@pixels[i+1][j+1])) - (bw(@pixels[i-1][j-1]) + bw(@pixels[i][j-1]) + bw(@pixels[i+1][j-1]))

        if @Gy[i][j] < 0
          @Gy[i][j] = 0
        elsif @Gy[i][j] > 255
          @Gy[i][j] = 255
        end
      end
    end
  end

  # Computes the grayscale value from a given pixel.
  #
  # @param rgb [Array<Integer>] An array representing a pixel's color channels.
  # @return [Integer] The grayscale value.
  def bw(rgb)=rgb.sum/3

  # Clears the temporary folder where temporary files are stored.
  def clear_tmp_folder!
    Dir.foreach('./tmp') do |file|
      next if file == '.' || file == '..'
  
      full_path = File.join('./tmp', file)
      if File.directory?(full_path)
        clear_tmp_folder(full_path)
        Dir.rmdir(full_path)
      else
        File.delete(full_path)
      end
    end
  rescue
    puts ".:: Error cleaning tmp folder"
  end
end