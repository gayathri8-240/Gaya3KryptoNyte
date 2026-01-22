name := "plic-chisel"

version := "1.0"

scalaVersion := "2.12.13"

scalacOptions ++= Seq(
  "-deprecation",
  "-feature",
  "-unchecked",
  "-language:reflectiveCalls",
)

libraryDependencies ++= Seq(
  "edu.berkeley.cs" %% "chisel3" % "3.5.4",
  "edu.berkeley.cs" %% "chiseltest" % "0.5.4" % "test"
)

resolvers ++= Seq(
  Resolver.sonatypeRepo("snapshots"),
  Resolver.sonatypeRepo("releases")
)

addCompilerPlugin("edu.berkeley.cs" % "chisel3-plugin" % "3.5.4" cross CrossVersion.full)
