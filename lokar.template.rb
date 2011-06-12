require 'strscan'
<?r
	# Code generation functions
	
	define_singleton_method :add_text do |text|
		align <<-CODE
			unless prev_text
				if prev_output
					output << "<<"
				else
					output << ";__output__<<"
					prev_output = true
				end
				prev_text = true
			end
			output << #{text}.inspect
		CODE
	end
	
	define_singleton_method :add_line do |text|
		align(dealign(add_text(text)) + "\nline += 1")
	end
	
	define_singleton_method :add_code do |code|
		align <<-CODE
			output << ("\\n" * (line - flushed)) << ";" << #{code}
			flushed = line
			prev_text = false
			prev_output = false
		CODE
	end
	
	define_singleton_method :set_output do
		align <<-CODE
			if prev_output
				output << "<<" << ("\\n" * (line - flushed)) << "("
			else
				output << ("\\n" * (line - flushed)) << ";__output__<<("
				prev_output = true
			end
			flushed = line
			prev_text = false
		CODE
	end
?>
module Lokar
	if defined? Tilt
		class Template < Tilt::Template
			def prepare
				@proc = Lokar.compile(data, eval_file)
			end

			def evaluate(scope, locals, &block)
				scope.instance_eval(&@proc).join
			end
		end
		
		Tilt.register Template, 'lokar'
	end
	
	def self.render(string, filename = '<Lokar>', binding = nil)
		eval("__output__ = []##{parse(string, filename).join}; __output__", binding, filename).join
	end
	
	def self.compile(string, filename = '<Lokar>', binding = nil)
		eval "Proc.new do __output__ = []##{parse(string, filename).join}; __output__ end", binding, filename
	end
	
	def self.parse(string, filename)
		scanner = StringScanner.new(string)
		prev_text = false
		prev_output = true
		output = []
		line = 1
		flushed = 1
		
		while true
			match = scanner.scan_until(/(?=<\?r(?:[ \t]|$)|\#?\##{|^[ \t]*%|(?:\r\n?|\n))/m)
			if match
				# Add the text before the match
				#{add_text 'match'}
				
				case # Find out what of the regular expression matched
					when match = scanner.scan(/\r\n?|\n/) # Parse newlines
						#{add_line 'match'}
						
					when scanner.match?(/</) # Parse <?r?> tags
						scanner.pos += 3
						result = scanner.scan_until(/(?=\?>)/m)
						raise "##{filename}:##{line}: Unterminated <\?r ?> tag" unless result
						
						#{add_code 'result'}
						
						scanner.pos += 2
					
					when scanner.skip(/\#/) # Parse ##{ } tags
						if scanner.skip(/\#/)
							#{add_text '\'#\''}
						else
							index = 1
							scanner.pos += 1
							
							#{set_output}
							
							while true
								result = scanner.scan_until(/(?=}|{)/m)
								raise "##{filename}:##{line}: Unterminated \#\{ } tag" unless result
								output << result
								case
									when scanner.skip(/{/)
										index += 1
										output << '{'
										
									when scanner.skip(/}/)
										index -= 1
										break if index == 0
										output << '}'
								end
							end
							
							output << ")"
						end
					
					else # Parse %, %% and %= lines
						result = scanner.scan(/[ \t]*%/)
						if scanner.skip(/%/)
							#{add_text 'result'}
						elsif scanner.skip(/=/)
							#{set_output}
							output << scanner.scan_until(/(?=\r\n|\n|\Z)/) << ")"
						else
							#{add_code 'scanner.scan_until(/\r\n|\n|\Z/)'}
						end
				end
			else # End of file
				unless scanner.eos?
					# Add the pending text
					#{add_text 'scanner.rest'}
				end
				break
			end
		end
		
		output
	end
end
