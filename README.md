git-automaton
===
git-automatonは定期的にDiffをとり、
自動的にコミットメッセージをつけれる程度の変更があったタイミングで
コミットメッセージをつけてcommitする。



## How to install

```
$ go install github.com/tottokug/git-automaton
```

## How To Use
```
$ cd path/to/git-repository
$ git-automaton 
```

## command option 
+ --max-interval, -n 
　diffの内容からコミットメッセージが作れなかった場合でも
 max-intervalで指定した秒数で必ずcommitする。
 default: 120

+ --locale 
  コミットメッセージの言語を指定する。
  default: en_US

+ --language, -l
  言語を指定する。
  default: Java-8



## 対応言語
|language|version|
|---|---|
|Java|7,8|

