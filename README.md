# 下記のポートフォリオのAWSインフラ構成に利用したterraformのファイル群
- ECS Fargateのコンテナ内にLaravelアプリケーションをデプロイする環境、およびそれを実現するCI/CD環境を用意
- このterraform群は、実際に利用した私のローカルPCにあるterraformプロジェクトからパラメータストアなど、一部情報を抜いて再度作成したものです。
- LaravelポートフォリオのAWSリソースは、このterraformで構成後、AWS画面上からも一部手動で修正しています。

## CI/CDの構成
- ソースステージ：Laravelアプリケーションのgithubリポジトリの特定のブランチの変更をCodeStarが検知
- ビルドステージ：CodeBuild
- デプロイステージ：ECS

## Laravelアプリケーションのgithubリポジトリ
laravel8-video-learning  
https://github.com/qei-ag49/laravel8-video-learning

## 実行方法
- `sh ./doProcess.sh`を実行
- AWSの画面上から、CodeStarのサービスでgithubとの接続を手動で行う
- ドメインを取得している「お名前.com」のネームサーバー画面に、Route53に表示されているドメイン4つを反映させる。待機する。
- ACMの証明書のリクエストが完了したら、ALBの設定で紐付ける
- お名前.comへの反映を確認したら、Route53にaliasでAレコードを作成する。東京リージョンのALBを指定する
- CodePipelineでデプロイが成功したら、ECSタスクのIPアドレスまたはドメインにhttpかhttpsでブラウザにアクセスする
- Laravelなどのアプリケーションが表示されれば成功です

## AWSリソース削除方法
- `sh ./doProcess2.sh`を実行

## githubに載せたくない箇所
- DBのパラメータストアの値など

## 命名規則
タグやリソース名に`by-tf`, `ByTf`といったサフィックスが付与されている。
これは、画面上で手動で作成したものと区別しやすくする意図で設定しています。
