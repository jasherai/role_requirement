require( File.join( File.dirname(__FILE__), "../role_generator_helpers" ))

class RoleGenerator < Rails::Generator::NamedBase
  
  include RoleGeneratorHelpers
  
  attr_accessor :users_table_name, 
    :users_model_name,
    :next_user_id
  
  def initialize(runtime_args, runtime_options = {})
    super
    @users_model_name = (runtime_args[0] || "User").classify
    
    @users_table_name = @users_model_name.tableize
    
    puts "Generating role column for #{@users_model_name}"
  end
  
  def manifest
    record do |m|
      # modify trohe User model unless it's already got RoleRequirement code in there
      content_for_insertion = render_template("_user_functions.erb")
      
      if insert_content_after(users_model_filename,
                              Regexp.new("class +#{users_model_name}"),
                              content_for_insertion,
                              :unless => lambda { |content| content.include? "def has_role?"; }
                              )
        
        puts "Added the following to the top of #{users_model_filename}:\n#{content_for_insertion}"
      else
        puts "Not modifying #{users_model_filename} because it appears that the funtion has_role? already exists."
      end
      
      # add the Role model
      
      # generate migration
      unless options[:skip_migration]
        m.migration_template 'add_role_to_users_migration.rb', 'db/migrate', :assigns => {
          :migration_name => "AddRoleTo#{users_model_name.pluralize.gsub(/::/, '')}"
        }, :migration_file_name => "add_role_to_#{users_table_name}"
      end
      
      add_dependencies_to_application_rb
      
    end
  end
  
  def render_template(name)
    template = File.read( File.join( File.dirname(__FILE__), "templates", name))
    ERB.new(template, nil, "-").result(binding)
  end
  
  def users_model_filename;  "app/models/#{users_model_name.underscore}.rb"; end;

protected
  
  def banner
    "Usage: #{$0} role [TargetUserModelName]"
  end
end