<h3>No AWS S3 credentials have been set</h3>
<p>In order to run the test suite, we need to set test S3 credentials for a bucket that you have access to read and write from/to. The test
will create multiple files under a /test "folder" and attempt to clean up after itself. The suite expects the following environment variables to be available:</p>

<ul>
	<li><code>TEST_S3_ACCESS_KEY</code></li>
	<li><code>TEST_S3_SECRET_KEY</code></li>
	<li><code>TEST_S3_BUCKET</code></li>
	<li><code>TEST_S3_REGION</code></li>
</ul>

<p>If running from Commandbox, you can set these with a <code>.env</code> file in the root of the <code>/tests/</code> directory. e.g.</p>
<pre><code>
TEST_S3_ACCESS_KEY=xxx
TEST_S3_SECRET_KEY=xxx
TEST_S3_BUCKET=my-test-bucket
TEST_S3_REGION=us-east-2
</code></pre>