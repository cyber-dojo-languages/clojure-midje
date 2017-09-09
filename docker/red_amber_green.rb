
lambda { |stdout,stderr,status|
  output = stdout + stderr
  return :red if /^FAILURE: .* failed./.match(output)
  return :green if /^All checks .* succeeded./.match(output)
  return :amber
}
