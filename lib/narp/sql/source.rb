require 'narp/node_extensions.rb'

module Narp
  module Sql 
    class Source
      include MyAppAccessor

      def _base_source 
        [ _unioned_tables_sql(:lhs), 
          join_type, 
          _unioned_tables_sql(:rhs), 
          joinkeys.predicate_hql
        ].flatten.compact.join("\n")
      end

      # Generate the hql for the lhs or rhs tables. Tables on each side are unioned.
      def _unioned_tables_sql(side = :lhs)
        tables = (side == :lhs ? lhs_tables : rhs_tables )
        return nil unless tables.any?

        ["(", tables.collect{|i| i.base_sql}.join("\nUNION ALL\n"), ") AS #{side}"].join("\n")
      end

      def to_s
        "SELECT\n" <<
          ("\t" << output_spec.src_column_expressions.join("\n\t, ")).sql_justify_on_alias << "\n" << 
        "FROM\n" << _base_source.myindent << "\n"
      end
    end
  end
end
