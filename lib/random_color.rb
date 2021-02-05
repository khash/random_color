require "random_color/version"

module RandomColor
  
  class Generator
    # randomColor by David Merfield under the CC0 license
    # https:#github.com/davidmerfield/randomColor/

    # Shared color dictionary
    COLOR_DICTIONARY = {}

    def initialize
      # Populate the color dictionary
      load_color_bounds
    end

    def generate(options = {})
      color_ranges = []
      # Check if we need to generate multiple colors
      count = options[:count] || 0
      colors = []

      # Value false at index i means the range i is not taken yet.
      count.times do
        color_ranges << false
      end

      totalCount = count == 0 ? 1 : count
      totalCount.times do
        colors << do_generate(options, color_ranges)
      end

      return colors
    end

    private

    def do_generate(options, color_ranges)
      @seed = nil

      if options.has_key?(:seed) 
        if options[:seed].is_a?(String)
          @seed = string_to_integer(options[:seed])
        elsif options[:seed].is_a?(Integer)
          @seed = options[:seed]
        else
          raise ArgumentError, 'seed should either be an integer or a string'
        end
      end

      # First we pick a hue (h)
      h = pick_hue(options, color_ranges)

      # Then use h to determine saturation (s)
      s = pick_saturation(h, options)

      # Then use s and h to determine brightness (b).
      b = pick_brightness(h, s, options)

      # Then we return the HSB color in the desired format
      return set_format([h,s,b], options);
    end

    def pick_hue(options, color_ranges)
      if color_ranges.length > 0 && options[:hue]
        hue_range = get_real_hue_range(options[:hue])

        hue = random_within(hue_range)

        #Each of @color_ranges.length ranges has a length equal approximately one step
        step = (hue_range[1] - hue_range[0]) / color_ranges.length

        j = ((hue - hue_range[0]) / step).to_i

        #Check if the range j is taken
        if color_ranges[j]
          j = (j + 2) % color_ranges.length
        else 
          color_ranges[j] = true
        end

        min = (hue_range[0] + j * step) % 359
        max = (hue_range[0] + (j + 1) * step) % 359

        hue_range = [min, max]

        hue = random_within(hue_range)

        if (hue < 0) 
          hue = 360 + hue
        end

        return hue
      else 
        hue_range = get_hue_range(options[:hue])

        hue = random_within(hue_range)
        # Instead of storing red as two separate ranges,
        # we group them, using negative numbers
        if hue < 0
          hue = 360 + hue
        end

        return hue
      end
    end

    def pick_saturation(hue, options)
      if options[:hue] == 'monochrome'
        return 0
      end

      if options[:luminosity] == 'random'
        return random_within([0,100])
      end

      saturation_range = get_saturation_range(hue)

      s_min = saturation_range[0]
      s_max = saturation_range[1]

      case options[:luminosity] 
      when 'bright'
        s_min = 55          
      when 'dark'
        s_min = s_max - 10
      when 'light'
        s_max = 55
      end

      return random_within([s_min, s_max])
    end

    def pick_brightness(h, s, options)
      b_min = get_minimum_brightness(h, s)
      b_max = 100

      case options[:luminosity] 
      when 'dark'
          b_max = b_min + 20
      when 'light'
          b_min = (b_max + b_min)/2
      when 'random'
          b_min = 0
          b_max = 100
      end

      return random_within([b_min, b_max])
    end

    def set_format (hsv, options) 
      case options[:format] 
      when 'hsvArray'
          return hsv;

      when 'hslArray'
          return HSVtoHSL(hsv)

      when 'hsl'
          hsl = HSVtoHSL(hsv)
          return 'hsl('+hsl[0]+', '+hsl[1]+'%, '+hsl[2]+'%)'

      when 'hsla'
          hslColor = HSVtoHSL(hsv)
          alpha = options[:alpha] || rand
          return 'hsla('+hslColor[0].to_s+', '+hslColor[1].to_s+'%, '+hslColor[2].to_s+'%, ' + alpha.to_s + ')'

      when 'rgbArray'
          return HSVtoRGB(hsv)

      when 'rgb'
          rgb = HSVtoRGB(hsv)
          return 'rgb(' + rgb.join(', ') + ')'

      when 'rgba'
          rgbColor = HSVtoRGB(hsv)
          alpha = options[:alpha] || rand
          return 'rgba(' + rgbColor.join(', ') + ', ' + alpha.to_s + ')'
      else
          return HSVtoHex(hsv)
      end

    end

    def get_minimum_brightness(h, s)
      lowerBounds = get_color_info(h)[:lowerBounds]
      lowerBounds.length.times do |i|

        s1 = lowerBounds[i][0]
        v1 = lowerBounds[i][1]

        s2 = lowerBounds[i+1][0]
        v2 = lowerBounds[i+1][1]

        if (s >= s1 && s <= s2)

          m = (v2 - v1)/(s2 - s1)
          b = v1 - m*s1

          return m*s + b
        end

      end

      return 0
    end

    def get_hue_range(color_input)
      if color_input.is_a?(Integer)
        return [color_input, color_input] if color_input < 360 && color_input > 0
      end

      if color_input.is_a?(String)
        if COLOR_DICTIONARY[color_input]
          color = COLOR_DICTIONARY[color_input]
          return color[:hue_range] if color[:hue_range]
        elsif color_input.match(/^#?([0-9A-F]{3}|[0-9A-F]{6})$/i)
          hue = HexToHSB(color_input)[0]
          return [hue, hue]
        end
      end

      return [0,360]
    end

    def get_saturation_range (hue) 
      return get_color_info(hue)[:saturation_range]
    end

    def get_color_info (hue)
      # Maps red colors to make picking hue easier
      if (hue >= 334 && hue <= 360)
        hue-= 360
      end


      COLOR_DICTIONARY.each do |color_name, color|
        if color[:hue_range] && hue >= color[:hue_range][0] && hue <= color[:hue_range][1]

          return COLOR_DICTIONARY[color_name]
        end
      end
      
      raise ArgumentError, 'color not found'
    end

    def random_within(range)
      if (@seed == nil)
        #generate random evenly distinct number from : https:#martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
        golden_ratio = 0.618033988749895
        r = rand
        r += golden_ratio
        r %= 1
        return (range[0] + r*(range[1] + 1 - range[0])).floor
      else 
        #Seeded random algorithm from http:#indiegamr.com/generate-repeatable-random-numbers-in-js/
        max = range[1] || 1
        min = range[0] || 0
        @seed = (@seed * 9301 + 49297) % 233280
        rnd = @seed / 233280.0
        return (min + rnd * (max - min)).floor
      end
    end

    def HSVtoHex (hsv)

      rgb = HSVtoRGB(hsv)

      def component_to_hex(c)
        return c.to_s(16).rjust(2, '0')
      end

      hex = '#' + component_to_hex(rgb[0]) + component_to_hex(rgb[1]) + component_to_hex(rgb[2])

      return hex
    end

    def defineColor (name, hue_range, lowerBounds) 

      s_min = lowerBounds[0][0]
      s_max = lowerBounds[lowerBounds.length - 1][0]

      b_min = lowerBounds[lowerBounds.length - 1][1]
      b_max = lowerBounds[0][1]

      COLOR_DICTIONARY[name] = {
        hue_range: hue_range,
        lowerBounds: lowerBounds,
        saturation_range: [s_min, s_max],
        brightnessRange: [b_min, b_max]
      }

    end

    def load_color_bounds
      defineColor(
        'monochrome',
        nil,
        [[0,0],[100,0]]
      )

      defineColor(
        'red',
        [-26,18],
        [[20,100],[30,92],[40,89],[50,85],[60,78],[70,70],[80,60],[90,55],[100,50]]
      )

      defineColor(
        'orange',
        [18,46],
        [[20,100],[30,93],[40,88],[50,86],[60,85],[70,70],[100,70]]
      )

      defineColor(
        'yellow',
        [46,62],
        [[25,100],[40,94],[50,89],[60,86],[70,84],[80,82],[90,80],[100,75]]
      )

      defineColor(
        'green',
        [62,178],
        [[30,100],[40,90],[50,85],[60,81],[70,74],[80,64],[90,50],[100,40]]
      )

      defineColor(
        'blue',
        [178, 257],
        [[20,100],[30,86],[40,80],[50,74],[60,60],[70,52],[80,44],[90,39],[100,35]]
      )

      defineColor(
        'purple',
        [257, 282],
        [[20,100],[30,87],[40,79],[50,70],[60,65],[70,59],[80,52],[90,45],[100,42]]
      )

      defineColor(
        'pink',
        [282, 334],
        [[20,100],[30,90],[40,86],[60,84],[80,80],[90,75],[100,73]]
      )

    end

    def HSVtoRGB (hsv)
      # this doesn't work for the values of 0 and 360
      # here's the hacky fix
      h = hsv[0]
      if (h == 0) 
        h = 1
      end

      if (h == 360) 
        h = 359
      end

      # Rebase the h,s,v values
      h = h.to_f/360
      s = hsv[1].to_f/100
      v = hsv[2].to_f/100

      h_i = (h*6).floor
      f = h * 6 - h_i
      p = v * (1 - s)
      q = v * (1 - f*s)
      t = v * (1 - (1 - f)*s)
      r = 256
      g = 256
      b = 256

      case h_i
      when 0
        r = v
        g = t
        b = p      
      when 1
        r = q
        g = v
        b = p
      when 2
        r = p
        g = v
        b = t
      when 3
        r = p
        g = q
        b = v
      when 4
        r = t
        g = p
        b = v
      when 5
        r = v
        g = p
        b = q
      end

      result = [(r*255).floor, (g*255).floor, (b*255).floor]

      return result
    end

    def HexToHSB (hex) 
      hex = hex.gsub(/^#/, '')
      hex = hex.length == 3 ? hex.gsub(/(.)/, '$1$1') : hex

      red = hex[0..2].to_i(16) / 255
      green = hex[3..5].to_i(16) / 255
      blue = hex[6..8].to_i(16) / 255

      cMax = [red, green, blue].max
      delta = cMax - [red, green, blue].min
      saturation = cMax ? (delta / cMax) : 0

      case (cMax) 
      when red
          return [ 60 * (((green - blue) / delta) % 6) || 0, saturation, cMax ]
      when green
          return [ 60 * (((blue - red) / delta) + 2) || 0, saturation, cMax ]
      when blue
          return [ 60 * (((red - green) / delta) + 4) || 0, saturation, cMax ]
      end
    end

    def HSVtoHSL (hsv) 
      h = hsv[0]
      s = hsv[1].to_f/100
      v = hsv[2].to_f/100
      k = (2-s)*v

      return [
        h,
        (s*v / (k<1 ? k : 2-k) * 10000).round / 100,
        k/2 * 100
      ]
    end

    def string_to_integer (str) 
      return str.bytes.sum
    end

    # get The range of given hue when options[:count] != 0
    def get_real_hue_range(color_hue) 
      if color_hue.is_a?(Integer)
        number = color_hue
        if number < 360 && number > 0
          return get_color_info(color_hue)[:hue_range]
        end
      elsif color_hue.is_a?(String)
        if COLOR_DICTIONARY[color_hue]
          color = COLOR_DICTIONARY[color_hue]
          if (color[:hue_range])
            return color[:hue_range]
          end
        elsif color_hue.match(/^#?([0-9A-F]{3}|[0-9A-F]{6})$/i)
          hue = HexToHSB(color_hue)[0]
          return get_color_info(hue)[:hue_range]
        end
      end
    end
  end
end
