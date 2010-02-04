require 'strscan'

module Lokar
	def self.render(string, filename = '<Lokar>', binding = nil)
		output = ["__output__ = []", *parse(string, filename), "\n__output__"]
		
		eval(output.join, binding, filename).join
	end
	
	def self.compile(string, filename = '<Lokar>', binding = nil)
		output = ["Proc.new do __output__ = []", *parse(string, filename), "\n__output__ end"]
		
		eval output.join, binding, filename
	end
	
	def self.parse(string, filename)
		scanner = StringScanner.new(string)
		output = []
		prev_text = false
		prev_output = true
		
		while true
			match = scanner.scan_until(/(?=<\?r[ \t]|\#{|^[ \t]*%)/m)
			if match
				# Add the text before the match
				if prev_text
					output.insert(-1, match.inspect)
				else
					if prev_output
						output << " << "
					else
						output << "\n__output__ << "
						prev_output = true
					end
					output << match.inspect
					prev_text = true
				end
				
				case # Find out what of the regular expression matched
					when scanner.match?(/</) # Parse <?r ?> tags
						scanner.pos += 3
						result = scanner.scan_until(/(?=\?>)/m)
						raise "#{filename}: Unterminated <?r ?> tag" unless result
						
						output << "\n"
						output << result
						
						prev_text = false
						prev_output = false
						
						scanner.pos += 2
					
					when scanner.match?(/\#/) # Parse #{ } tags
						index = 1
						scanner.pos += 2
						
						if prev_output
							output << " << ("
						else
							output << "\n__output__ << ("
							prev_output = true
						end
						
						while true
							result = scanner.scan_until(/(?=}|{)/m)
							raise "#{filename}: Unterminated \#{ } tag" unless result
							output << result
							case 
								when scanner.scan(/{/)
									index += 1
									output << '{'
									
								when scanner.scan(/}/)
									index -= 1
									break if index == 0
									output << '}'
							end
						end
						
						output << ")"
						
						prev_output = true
						prev_text = false
					
					else # Parse %, %% and %= lines
						result = scanner.scan(/[ \t]*%/)
						if scanner.scan(/%/)
							result = result.inspect
							if prev_text
								output << result
							else
								if prev_output
									output << " << "
								else
									output << "\n__output__ << "
									prev_output = true
								end
								output << result
								prev_text = true
							end
						else
							if scanner.scan(/=/)
								if prev_output
									output << " << ("
								else
									output << "\n__output__ << ("
									prev_output = true
								end
								output << scanner.scan_until(/(\r\n|\n|\Z)/) 
								output << ")"
							else
								output << "\n"
								output << scanner.scan_until(/(\r\n|\n|\Z)/)
								prev_output = false
							end
							prev_text = false
						end
				end
			else # End of file
				unless scanner.eos?
					# Add the pending text
					if prev_text
						output << scanner.rest.inspect
					else
						if prev_output
							output << " << "
						else
							output << "\n__output__ << "
						end
						output << scanner.rest.inspect
					end
				end
				break
			end
		end
		
		output
	end
end
