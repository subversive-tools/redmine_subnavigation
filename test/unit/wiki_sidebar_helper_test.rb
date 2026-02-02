require File.expand_path('../../test_helper', __FILE__)
require_relative '../../lib/redmine_subnavigation/wiki_sidebar_helper'

class WikiSidebarHelperTest < ActiveSupport::TestCase
  include RedmineSubnavigation::WikiSidebarHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include Rails.application.routes.url_helpers

  def setup
    @project = Project.new(identifier: 'test-project', name: 'Test Project')
    @project.enabled_modules.build(name: 'wiki')
    @project.save!(validate: false)

    @wiki = Wiki.new(project: @project, start_page: 'Start')
    @wiki.save!
    @project.wiki = @wiki
  end

  def test_render_sidebar_navigation_none_mode
    assert_equal '', render_sidebar_navigation(@project, 'none')
  end

  def test_render_wiki_sidebar_tree_empty
    assert_equal '', render_wiki_sidebar_tree(@project)
  end

  def test_render_headers_markdown
    page = WikiPage.new(wiki: @wiki, title: 'TestPage')
    page.content = WikiContent.new(text: "## Header 1\n## Header 2")
    
    html = render_headers(page)
    assert_match /Header 1/, html
    assert_match /Header 2/, html
    assert_match /class="wiki-page-headers"/, html
  end

  def test_render_headers_textile
    page = WikiPage.new(wiki: @wiki, title: 'TestPage')
    page.content = WikiContent.new(text: "h2. Textile Header")
    
    html = render_headers(page)
    assert_match /Textile Header/, html
  end
end
