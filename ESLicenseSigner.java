import org.apache.lucene.util.BytesRef;
import org.apache.lucene.util.BytesRefIterator;
import org.elasticsearch.common.bytes.BytesArray;
import org.elasticsearch.common.bytes.BytesReference;
import org.elasticsearch.common.hash.MessageDigests;
import org.elasticsearch.common.xcontent.*;
import org.elasticsearch.xcontent.XContentBuilder;
import org.elasticsearch.xcontent.XContentFactory;
import org.elasticsearch.xcontent.XContentType;
import org.elasticsearch.license.CryptUtils;
import org.elasticsearch.license.License;
import org.elasticsearch.xcontent.ToXContent;

import java.nio.ByteBuffer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import java.util.Collections;
import java.util.Map;
import java.util.Random;

/**
 * Elasticsearch License Signer - Simplified Version
 * 
 * Usage:
 *   1. Generate key pair: ./gen-keys.sh
 *   2. Create license.json with your license details
 *   3. Sign: java -cp .:es-modules/* ESLicenseSigner license.json private.key
 *   4. Output: signed-license.txt (base64 encoded signed license)
 */
public class ESLicenseSigner {

    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.err.println("Usage: java ESLicenseSigner <license.json> <private.key> [output.txt]");
            System.exit(1);
        }

        Path licensePath = Paths.get(args[0]);
        Path privateKeyPath = Paths.get(args[1]);
        Path outputPath = args.length >= 3 ? Paths.get(args[2]) : Paths.get("signed-license.txt");

        // 1. Load license from JSON
        BytesArray bytes = new BytesArray(Files.readAllBytes(licensePath));
        License licenseSpec = License.fromSource(bytes, XContentType.JSON);

        // 2. Serialize to JSON
        XContentBuilder contentBuilder = XContentFactory.contentBuilder(XContentType.JSON);
        final Map<String, String> viewMode = Collections.singletonMap(License.LICENSE_SPEC_VIEW_MODE, "true");
        licenseSpec.toXContent(contentBuilder, new ToXContent.MapParams(viewMode));
        
        // 3. Load private key (PKCS8 format)
        String privateKeyPEM = Files.readString(privateKeyPath);
        String keyContent = privateKeyPEM
            .replace("-----BEGIN PRIVATE KEY-----", "")
            .replace("-----END PRIVATE KEY-----", "")
            .replaceAll("\\s", "");
        
        byte[] keyBytes = Base64.getDecoder().decode(keyContent);
        PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(keyBytes);
        PrivateKey privateKey = KeyFactory.getInstance("RSA").generatePrivate(spec);

        // 4. Sign the JSON content
        Signature rsa = Signature.getInstance("SHA512withRSA");
        rsa.initSign(privateKey);
        
        BytesRefIterator iterator = BytesReference.bytes(contentBuilder).iterator();
        BytesRef ref;
        while ((ref = iterator.next()) != null) {
            rsa.update(ref.bytes, ref.offset, ref.length);
        }
        byte[] signedContent = rsa.sign();

        // 5. Generate magic bytes
        byte[] magic = new byte[13];
        new Random().nextBytes(magic);

        // 6. Calculate public key fingerprint
        Path parentPath = privateKeyPath.getParent();
        if (parentPath==null) parentPath=Paths.get(".");
        Path publicKeyPath = parentPath.resolve("public.key");
        byte[] publicKeyBytes = Files.readAllBytes(publicKeyPath);
        MessageDigest sha256 = MessageDigests.sha256();
        sha256.update(publicKeyBytes);
        byte[] pubKeyFingerprint = sha256.digest();

        // 7. Assemble binary structure
        int version = License.VERSION_ENTERPRISE;
        ByteBuffer byteBuffer = ByteBuffer.allocate(
            4 + 4 + magic.length + 4 + pubKeyFingerprint.length + 4 + signedContent.length
        );
        
        byteBuffer.putInt(version)
            .putInt(magic.length).put(magic)
            .putInt(pubKeyFingerprint.length).put(pubKeyFingerprint)
            .putInt(signedContent.length).put(signedContent);

        // 8. Encode and output
        String finalLicenseStr = Base64.getEncoder().encodeToString(byteBuffer.array());
        Files.writeString(outputPath, finalLicenseStr+"\n");
        System.out.println("Output saved to: " + outputPath.toAbsolutePath());
    }
}
