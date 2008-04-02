=begin
=Ruby/SpiderMonkey
-------------------------------------------------
nazoking@gmail.com
http://nazo.yi.org/rubysmjs/
-------------------------------------------------

Ruby で JavaScript を使うためのモジュールです。

現在アルファバージョンです。
クラス名、メソッド名などが変更される可能性があります。

==
サーバサイドでJavaScriptが使えると色々幸せだろう。


==インストール
 ruby extconf.rb
 make
 make install

ただし、現在まだアルファバージョンなので、インストールしない方がいいでしょう。
Debian/sarge 以外で上手く動作した方はご一報ください。
 Debian/sid , FreeBSD6/ppc でも動いたという報告が

上手く動作しない方は、上手く動作するようにしてください…

test.rb はテストコードです。

 ruby test.rb

で実行します。通らないテストがあっても気にしない！
（あるいは、テストが通るように修正してパッチを nazoking@gmail.com まで）


==使用法

require "spidermonkey"

make install していない場合は、require "./spidermonkey" などと、spidermonkey.so の場所をパス付きで指定しましょう。

SpiderMonkey::evalget("1").to_ruby #=> 1

のようにできます。


=== JavaScriptから見たRubyオブジェクト

　Rubyオブジェクト rbobj は Context::set_property( "name", rbobj )で JavaScript に name として渡すことができます。Rubyから渡されたオブジェクトは、対応するJavaScriptプリミティブ値がある場合、その値に変換されます。ない場合はRubyオブジェクトをラップしたJavaScriptオブジェクトになります。

　Rubyでは、オブジェクトのプロパティーという概念がなく、オブジェクトに対してアクセスできる手段はメソッドのみです。また、JavaScriptにはない概念として、定数という種類の変数があります。Ruby/SpiderMonkeyでは、Rubyオブジェクトをラップする際に、次のようにメソッドとプロパティーが設定されているものとして振る舞います。

* Rubyの定数　→　プロパティー
* Rubyのメソッドの内、引数が0個固定のもの　→　プロパティー
* Rubyのメソッドの内、引数が可変あるいは一個以上のもの　→　メソッド

この方法の問題点は可変引数０個から複数のメソッドの扱いがわかりにくいことです。が、他に方法が思いつかなかったので、現状こうなっています。


==リファレンス

SpiderMonkey では、ランタイムを作成し、ランタイム上でコンテキストを作成し、そのコンテキストに対してスクリプトを実行します。
が、手間がかかるため、ランタイムはモジュールがロードされた時点で作成されます。また、default_context というコンテキストを用意し、SpiderMonkeyクラスオブジェクトに対してメッセージを投げ、該当するメソッドが SpiderMonkeyクラスオブジェクトにない場合、デフォルトコンテキストに委譲されます。

同じく Contextオブジェクトのメソッドも、該当するものがない場合、globalオブジェクトに委譲されます。

=== SpiderMonkey

:SpiderMonkey::LIB_VERSION
  SpiderMonkeyのバージョンが文字列で返ります

:SpiderMonkey::eval( code )
  デフォルトコンテキスト上で javascript-code をevalします。
  結果の SpiderMonkey::Value が返ります。

:SpiderMonkey::evaluate( code )
  デフォルトコンテキスト上で javascript-code をevalします。
  結果の Rubyオブジェクト が返ります。
    SpiderMonkey::evalate( code ).to_ruby
  と同意です

=== SpiderMonkey::Context
コンテキスト情報のラッパークラスです。

:SpiderMonkey::Context.new( stack_size=8192 )
  新しいコンテキストを作成します。

:SpiderMonkey::Context#eval( code )
  Javascriptコード code を、コンテキスト上で実行します。
  結果がプリミティブ値の場合、対応するRubyのオブジェクトが返ります。
  結果がオブジェクトの SpiderMonkey::Value が返ります。
  結果が Ruby から渡されたオブジェクトであった場合、元のRubyオブジェクトが返ります。

:SpiderMonkey::Context#eval( code )
  Javascriptコード code を、コンテキスト上で実行します。
  結果の SpiderMonkey::Value が返ります。

:SpiderMonkey::Context#evaluate( code )
  Javascriptコード code を、コンテキスト上で実行します。
  結果の Rubyオブジェクトが返ります。
    SpiderMonkey::Context#evalget( code ).to_ruby
  と同意です

:SpiderMonkey::Context#version
  ContextのJavaScriptのバージョンを文字列で返します。

:SpiderMonkey::Context#version=
  ContextのJavaScriptのバージョンを文字列で設定します。
  設定できないバージョンの場合は SpiderMonkey::Error が発生します。

:SpiderMonkey::Context#gc()
  ガベレージコレクションを発生させます。主にデバッグ用

:SpiderMonkey::Context#running?
  eval 実行中ならtrueを返します。コールバック関数中にrubyが呼ばれたなら trueになります。

:SpiderMonkey::Context#global
  globalオブジェクトのSpiderMonkey::Valueラッパーを返します。

=== SpiderMonkey::Value
  JavaScriptオブジェクトのRubyラッパーです。
  JavaScriptから渡される値は、プリミティブ値以外はこのクラスにラップされます。

:SpiderMonkey::Value#to_ruby
  適当なRubyオブジェクトに変換して返します。
  undefined および null は nil に変換されます。
  ObjectはHashに、ArrayはArrayに変換されます。
  ObjectやArrayの子（プロパティー）も含めて変換します。
  function型、function型を含むObjectを変換しようとすると ConvertError が発生します。
  Rubyから渡されてきたオブジェクトは元のRubyオブジェクトになります。
  JavaScript上でArrayに個別のプロパティーを設定しても、その値は変換されません。

:SpiderMonkey::Value#to_a
  Rubyの Array にして返します。
  JavaScript の Array以外のものは適当なオブジェクトにした後に to_a メソッドを呼び出します。
  JavaScript上でArrayに個別のプロパティーを設定しても、その値は変換されません。
  JavaScriptの関数は変換できません。（SpiderMonkey::ConvertError が起こります）

:SpiderMonkey::Value#to_i
  Rubyの Integer にして返します。

:SpiderMonkey::Value#to_f
  Rubyの Float にして返します。

:SpiderMonkey::Value#to_num
  Rubyの Integer または Float にして返します。

:SpiderMonkey::Value#to_h
  Rubyの Hashにして返します。
  オブジェクト以外は例外を返します。
  関数を含むオブジェクトは変換できません。

:SpiderMonkey::Value#to_bool
  true または false が返ります。JavaScript基準で変換されるので、空文字、0などはfalse になります。

:SpiderMonkey::Value#typeof
  typeof x をJavaScript上で行い、その結果の文字列を返します。

:SpiderMonkey::Value#function( name , &proc )
  JavaScriptオブジェクトに name という名前で関数を定義します。
  その関数が呼ばれると、proc が実行されます

:SpiderMonkey::Value#call( name , args... )
  JavaScriptオブジェクトの関数を呼び出します。
  args が引数になります。
  返値は SpiderMonkey::Value です

:SpiderMonkey::Value#set_property( name, value )
  JavaScriptオブジェクトに name という名前でプロパティーを定義します。

:SpiderMonkey::Value#get_property( name )
  JavaScriptオブジェクトの name という名前のプロパティーを取得します。
  SpiderMonkey::Value オブジェクトが返ります。

=end

