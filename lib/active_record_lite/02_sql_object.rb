require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'

class MassObject
  def self.parse_all(results)
    results.map do |hash|
      self.new( hash )
    end
  end
end

class SQLObject < MassObject
  def self.columns
    rows = DBConnection.execute2(<<-SQL)
    SELECT *
    FROM #{table_name}
    SQL

    rows.first.map { |row_name| row_name.to_sym }
  end
  
  def self.setup_accessors
    self.columns.each do |column_name|
      define_method(column_name) do
        attributes[column_name] 
      end 
      
      define_method("#{column_name}=") do |value|
        attributes[column_name] = value
      end
    end 
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.downcase.pluralize
  end

  def self.all
    result_hashes = DBConnection.execute(<<-SQL)
    SELECT * FROM "#{table_name}"
    SQL
    
    self.parse_all(result_hashes)
  end

  def self.find(id)
    target = DBConnection.execute(<<-SQL, id)
    SELECT * FROM "#{table_name}"
    WHERE id = ?
    SQL
    self.new(target.first)
  end

  def attributes
    @attributes ||= Hash.new
  end

  def insert
    value_string = (["?"]*col_names.size).join(',')
    cols = col_names.map(&:to_sym)
    vals = attribute_values
    p "value string"
    p value_string
    puts
    p "col_names"
    p *cols
    puts
    p "vals"
    p vals
    
  end
  
  def col_names
    attributes.keys
  end

  def initialize(params = {})
    self.class.setup_accessors 
    
    params.each do |k,v|
      attributes[k.to_sym] = v
    end
  end

  def save
    # ...
  end

  def update
    # ...
  end

  def attribute_values
    attributes.values
  end
end
