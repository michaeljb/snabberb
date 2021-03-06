# frozen_string_literal: true

require 'execjs'
require 'opal'
require 'spec_helper'

describe Snabberb do
  before :all do
    builder = Opal::Builder.new
    builder.build('opal')
    builder.build('snabberb')
    @js_context = ExecJS.compile(builder.to_s)
  end

  def evaluate(script)
    @js_context.eval(Opal.compile(script).strip.chomp(';'))
  end

  def elements_to_html(elements)
    script = <<-RUBY
      class Child < Snabberb::Component
        needs :value

        def render
          h(:div, "child with value \#{@value}")
        end
      end

      class Parent < Snabberb::Component
        def render
          #{elements}
        end
      end

      Parent.html
    RUBY

    evaluate(script)
  end

  it 'has a version number' do
    expect(Snabberb::VERSION).not_to be nil
  end

  describe '.prerender' do
    it 'generates the correct prerender script' do
      script = Snabberb.prerender_script(
        'layout',
        'app',
        'app_id',
        need: 'hello',
        array_need: [1],
        hash_need: { x: 1 },
      )
      expect(script).to eq(
        <<~JS
          Opal.$$.layout.$html(Opal.hash({
            application: Opal.$$.app.$new(null, Opal.hash({"need":"hello","array_need":[1],"hash_need":{"x":1}})).$render(),
            javascript_include_tags: '',
            attach_func: 'Opal.$$.app.$attach("app_id", Opal.hash({"need":"hello","array_need":[1],"hash_need":{"x":1}}))'
          }))
        JS
      )
    end
  end

  describe '.html' do
    it 'can render a div' do
      html = elements_to_html(
        <<-RUBY
          h(:div, { style: { width: '100px' } }, 'Hello World')
        RUBY
      )

      expect(html).to eq('<div style="width: 100px">Hello World</div>')
    end

    it 'can render children' do
      html = elements_to_html(
        <<-RUBY
          h(:div, { style: { width: '100px' } }, [
            h(:div, { class: { active: true } }),
            h(:span, { style: { width: '100px' } }),
          ])
        RUBY
      )

      expect(html).to eq('<div style="width: 100px"><div class="active"></div><span style="width: 100px"></span></div>')
    end

    it 'can render components' do
      html = elements_to_html(
        <<-RUBY
          h(:div, [
            h(:span, 'a span'),
            h(Child, value: 2),
          ])
        RUBY
      )

      expect(html).to eq('<div><span>a span</span><div>child with value 2</div></div>')
    end
  end
end
