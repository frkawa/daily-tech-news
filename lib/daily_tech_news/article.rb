# frozen_string_literal: true

module DailyTechNews
  Article = Data.define(:url, :title, :body, :published_at, :source, :tags)
end
