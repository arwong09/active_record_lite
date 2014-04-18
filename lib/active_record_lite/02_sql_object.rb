require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'
require 'debugger'

class MassObject
  def self.parse_all(results)
    results.map do |hash|
      self.new( hash )
    end
  end
end

class SQLObject < MassObject
  def self.columns
    if @columns.nil?
      rows = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{table_name}
      SQL

      @columns = rows.first.map { |row_name| row_name.to_sym }
      self.setup_accessors(@columns)
    end
    @columns
    
  end
  
  def self.setup_accessors(column_names)
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
    columns = self.class.columns
    q_marks = (["?"]*columns.length).join(', ')
    cols = columns.join(', ')
    vals = attribute_values
    
    query_string = <<-SQL
    INSERT INTO
    #{self.class.table_name} (#{cols})
     VALUES
     (#{q_marks})
    SQL
    
    DBConnection.execute(query_string, *vals)
  end
  
  def col_names
    attributes.keys
  end

  def initialize(params = {})
    params.each do |k,v|
      raise "Invalid attribute" unless self.class.columns.include?(k.to_sym)
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
    self.class.columns.map{|attr_name| self.send(attr_name)}
  end
end
