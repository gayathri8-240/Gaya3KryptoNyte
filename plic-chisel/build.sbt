name := "plic-chisel"

version := "1.0"

scalaVersion := "2.12.13"

scalacOptions ++= Seq(
  "-deprecation",
  "-feature",
  "-unchecked",
  "-language:reflectiveCalls",
  "-target:jvm-1.8",
)

libraryDependencies ++= Seq(
  "edu.berkeley.cs" %% "chisel3" % "3.6.0",
  "edu.berkeley.cs" %% "chiseltest" % "0.6.0" % "test"
)

resolvers ++= Seq(
  Resolver.sonatypeOssRepos("snapshots").head,
  Resolver.sonatypeOssRepos("releases").head
)

addCompilerPlugin("edu.berkeley.cs" % "chisel3-plugin" % "3.6.0" cross CrossVersion.full)
