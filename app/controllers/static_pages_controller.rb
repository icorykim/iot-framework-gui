class StaticPagesController < ApplicationController

  def home
  	@home_page = true

		sort = { "user_ranking.average" => "desc" }
		query = { match_all: {} }
		res = Api.post("/_search?from=0&size=10", { sort: sort, query: query })

		@streams = res['streams']['hits']['hits']

		q = "stream_id="
		@streams.each do |stream|
			q = q + "," + "#{stream['_id']}"
		end

		res = Api.get("/_history?" + q + "&size=1")

		@values_ = res['history']

		@values = Hash.new("NO DATA")
		@values_.each do |val|
			if val['data'] != []
				@values["#{val['stream_id']}"] = val['data'][0]['value']
			end
		end
  end

  def help
  end

  def about
  end

  def faq
  end

  def manual
  end

  def privacy
  end

  def api
  end

  def security
  end

  def terms
  end
end
