module LuckyCache
  struct NullStore < BaseStore
    def initialize
    end

    def fetch(key : String, as : Array(T).class, &) forall T
      yield
    end

    def fetch(key : String, as : T.class, &) forall T
      yield
    end
  end
end
