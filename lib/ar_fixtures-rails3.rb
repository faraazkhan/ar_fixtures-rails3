require 'erb'

# Extension to make it easy to read and write data to a file.
class ActiveRecord::Base

  class << self

    # Writes content of this table to db/table_name.yml, or the specified file.
    #
    # Writes all content by default, but can be limited.
    def dump_to_file(path=nil, limit=nil, opts={})
      opts[:limit] = limit if limit
      path ||= "db/#{table_name}.yml"
      write_file(File.expand_path(path, ::Rails.root.to_s), self.find(:all, opts).to_yaml)
      habtm_to_file
    end

    # dump the habtm association table
    def habtm_to_file
      path ||= "db/#{table_name}.yml"
      joins = self.reflect_on_all_associations.select { |j|
        j.macro == :has_and_belongs_to_many
      }
      joins.each do |join|
        hsh = {}
        connection.select_all("SELECT * FROM #{join.options[:join_table]}").each_with_index { |record, i|
          hsh["join_#{'%05i' % i}"] = record
        }
        write_file(File.expand_path("db/#{join.options[:join_table]}.yml", ::Rails.root.to_s), hsh.to_yaml(:SortKeys => true))
      end
    end

    ##
    # Delete existing data in database and load fresh from file in db/table_name.yml
    #
    # ERB tags are also possible, as with the rest of Rails fixtures.
    def load_from_file(path=nil)
      path ||= "db/#{table_name}.yml"

      self.destroy_all

      if connection.respond_to?(:reset_pk_sequence!)
        connection.reset_pk_sequence!(table_name)
      end

      rawdata = File.read(File.expand_path(path, ::Rails.root.to_s))
      erb_data = ERB.new(rawdata).result
      records = YAML::load( erb_data )

      records.each do |record|
        unless 'test' == RAILS_ENV
          puts "______________"
          puts record.to_yaml
          puts "______________"
        end
        
        record_copy = self.new(record.attributes)
        record_copy.id = record.id

        # For Single Table Inheritance
        klass_col = record.class.inheritance_column.to_sym
        if record[klass_col]
          record_copy.type = record[klass_col]
        end

        record_copy.save
      end

      if connection.respond_to?(:reset_pk_sequence!)
        connection.reset_pk_sequence!(table_name)
      end
    end

    # Write a file that can be loaded with +fixture :some_table+ in tests.
    # Uses existing data in the database.
    #
    # Will be written to +test/fixtures/table_name.yml+. Can be restricted to some number of rows.
    def to_fixture(limit=nil, key=nil, opts={})
      opts[:limit] = limit if limit

      write_file(File.expand_path("test/fixtures/#{table_name}.yml", ::Rails.root.to_s),
      self.find(:all, opts).inject({}) { |hsh, record|
        hsh.merge((record.attributes[key.to_s] || "#{table_name.singularize}_#{'%05i' % record.id rescue record.id}") => record.attributes)
      }.to_yaml(:SortKeys => true))
      habtm_to_fixture
    end

    # Write the habtm association table
    def habtm_to_fixture
      joins = self.reflect_on_all_associations.select { |j|
        j.macro == :has_and_belongs_to_many
      }
      joins.each do |join|
        hsh = {}
        connection.select_all("SELECT * FROM #{join.options[:join_table]}").each_with_index { |record, i|
          hsh["join_#{'%05i' % i}"] = record
        }
        write_file(File.expand_path("test/fixtures/#{join.options[:join_table]}.yml", ::Rails.root.to_s), hsh.to_yaml(:SortKeys => true))
      end
    end

    # Generates a basic fixture file in test/fixtures that lists the table's field names.
    #
    # You can use it as a starting point for your own fixtures.
    #
    #  record_1:
    #    name:
    #    rating:
    #  record_2:
    #    name:
    #    rating:
    #
    # TODO Automatically add :id field if there is one.
    def to_skeleton
      record = {
        "record_1" => self.new.attributes,
        "record_2" => self.new.attributes
      }
      write_file(File.expand_path("test/fixtures/#{table_name}.yml", ::Rails.root.to_s),
      record.to_yaml)
    end

    def write_file(path, content) # :nodoc:
      f = File.new(path, "w+")
      f.puts content
      f.close
    end

    # Taken from http://pastebin.com/ng8GnTvA#
    # Read the habtm association table
    def load_habtm_from_file
      joins = self.reflect_on_all_associations.select { |j| j.macro == :has_and_belongs_to_many }
      joins.each do |join|
        join_table_name = join.options[:join_table]
 
        connection.delete("DELETE FROM #{join_table_name}")
 
        records = YAML::load( File.open( File.expand_path("db/#{join_table_name}.yml", ::Rails.root.to_s) ) )
        records.each do |record|
          col1 ||= record[1].keys[0]
          col2 ||= record[1].keys[1]
 
          connection.insert("INSERT INTO #{join_table_name} (#{col1}, #{col2}) VALUES (#{record[1][col1]}, #{record[1][col2]})")
        end
      end
    end

  end

end
