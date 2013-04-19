module Reclassifier
  class Bayes
    # The class can be created with one or more categories, each of which will be
    # initialized and given a training method.  The categories are specified as
    # symbols.  E.g.,
    #      b = Reclassifier::Bayes.new :interesting, :uninteresting, :spam
    def initialize(*categories)
      @categories = {}

      @docs_in_category_count = {}
    end

    #
    # Provides a general training method for all categories specified in Bayes#new
    # For example:
    #     b = Reclassifier::Bayes.new :this, :that, :the_other
    #     b.train :this, "This text"
    #     b.train :that, "That text"
    #     b.train :the_other, "The other text"
    def train(category, text)
      @docs_in_category[category] ||= 0
      @docs_in_category[category] += 1

      text.word_hash.each do |word, count|
        @categories[category] ||= {}
        @categories[category][word] ||= 0

        @categories[category][word] += count

        @total_words ||= 0
        @total_words += count
      end
    end

    #
    # Provides an untraining method for all categories specified in Bayes#new
    # Be very careful with this method.
    #
    # For example:
    #     b = Reclassifier::Bayes.new :this, :that, :the_other
    #     b.train :this, "This text"
    #     b.untrain :this, "This text"
    def untrain(category, text)
      @docs_in_category_count[category] -= 1

      text.word_hash.each do |word, count|
        if @total_words >= 0
          orig = @categories[category][word]

          @categories[category][word] ||= 0
          @categories[category][word] -= count

          if @categories[category][word] <= 0
            @categories[category].delete(word)
            count = orig
          end

          @total_words -= count
        end
      end
    end

    #
    # Returns the scores in each category the provided +text+. E.g.,
    #    b.classifications "I hate bad words and you"
    #    =>  {"Uninteresting"=>-12.6997928013932, "Interesting"=>-18.4206807439524}
    # The largest of these scores (the one closest to 0) is the one picked out by #classify
    def classifications(text)
      @categories.each do |category, category_word_counts|
        # prior
        score = Math.log(@docs_in_category_count[category] / @docs_in_category_count.values.reduce(:+).to_f)

        # likelihood
        text.word_hash.each do |word, count|
          if category_word_counts.include?(word)
            score += count * Math.log((@category_word_counts[word] + 1) / (@category_word_counts.values.reduce(:+) + @categories.values.reduce(Set.new) {|set, word_counts| set.merge(word_counts.keys)}.count).to_f)
          end
        end

        score
      end
    end

    #
    # Returns the classification of the provided +text+, which is one of the
    # categories given in the initializer. E.g.,
    #    b.classify "I hate bad words and you"
    #    =>  :uninteresting
    def classify(text)
      (classifications(text).sort_by { |a| -a[1] })[0][0]
    end

    #
    # Provides a list of category names
    # For example:
    #     b.categories
    #     =>   [:this, :that, :the_other]
    def categories # :nodoc:
      @categories.keys
    end

    #
    # Allows you to add categories to the classifier.
    # For example:
    #     b.add_category "Not spam"
    #
    # WARNING: Adding categories to a trained classifier will
    # result in an undertrained category that will tend to match
    # more criteria than the trained selective categories. In short,
    # try to initialize your categories at initialization.
    def add_category(category)
      @categories[category] = {}
    end

    alias append_category add_category
  end
end
