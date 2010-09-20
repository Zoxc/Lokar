task :test do
	require_relative 'lokar'
	
	input = File.open('test.html', 'r') { |file| file.read }
	correct = File.open('correct.html', 'r') { |file| file.read }
	
	def a(link)
		"<a href=\"#{link}\">#{link}</a>"
	end
	
	@args = []
	
	5.times { |i| @args << "Argument #{i}"}
	
	output = Lokar.render(input, 'test.html', binding)
	
	if correct != output
		File.open('failed.html', 'w') { |file| file.write output }
		raise "Output of Lokar is incorrect. Compare failed.html to correct.html."
	else
		File.delete('failed.html') if File.exists?('failed.html')
	end
end

task :default do
	require 'lokar'
	
	__output__ = nil
	
	define_singleton_method :strip do |string|
		lines = string.split("\n")
		strip = lines.map { |line| /[ \t]*/.match(line)[0] }.min_by { |line_space| line_space.length }.length
		lines.map { |line| line[strip..-1] }.join("\n")
	end
	
	define_singleton_method :dealign do |string|
		space = /[ \t]*/.match(__output__.join.split("\n").last)[0]
		strip(space + string)
	end
	
	define_singleton_method :align do |string|
		space = /[ \t]*/.match(__output__.join.split("\n").last)[0]
		lines = strip(string).split("\n")
		first = lines.shift
		([first] + lines.map { |line| space + line }).join("\n")
	end
	
	input = File.open('lokar.template.rb', 'r') { |file| file.read }
	
	File.open('lokar.rb', 'w') do |file|
		file.write Lokar.render(input, 'lokar.template.rb', binding)
	end
	
	`rake test`
end