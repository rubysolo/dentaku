module Dentaku
  module StringCasing
    def standardize_case(value)
      case_sensitive ? value : value.downcase
    end
  end
end
