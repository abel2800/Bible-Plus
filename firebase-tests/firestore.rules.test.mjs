import fs from "node:fs";
import test, { after, before } from "node:test";
import assert from "node:assert/strict";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc } from "firebase/firestore";

let environment;
const [emulatorHost = "127.0.0.1", emulatorPort = "8080"] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080"
).split(":");

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "biblepulse-emulator",
    firestore: {
      rules: fs.readFileSync("../firestore.rules", "utf8"),
      host: emulatorHost,
      port: Number(emulatorPort),
    },
  });
});

after(async () => environment?.cleanup());

test("study records are isolated by authenticated owner", async () => {
  const record = {
    kind: "note",
    id: "note-1",
    ownerId: "alice",
    updatedAt: "2026-07-17T00:00:00.000Z",
    deletedAt: null,
    data: { text: "private" },
  };
  const alice = environment.authenticatedContext("alice").firestore();
  const bob = environment.authenticatedContext("bob").firestore();
  const anonymous = environment.unauthenticatedContext().firestore();
  const path = "users/alice/study/note_note-1";

  await assertSucceeds(setDoc(doc(alice, path), record));
  await assertSucceeds(getDoc(doc(alice, path)));
  await assertFails(getDoc(doc(bob, path)));
  await assertFails(getDoc(doc(anonymous, path)));
  assert.equal((await getDoc(doc(alice, path))).data().ownerId, "alice");
});

test("a user cannot forge the owner field", async () => {
  const alice = environment.authenticatedContext("alice").firestore();
  await assertFails(
    setDoc(doc(alice, "users/alice/study/note_forged"), {
        kind: "note",
        id: "forged",
        ownerId: "bob",
        updatedAt: "2026-07-17T00:00:00.000Z",
        data: {},
      }),
  );
});

test("community writes enforce authorship and moderation fields", async () => {
  const validPost = {
    authorId: "alice",
    body: "Encouragement",
    createdAt: "2026-07-17T00:00:00.000Z",
    updatedAt: "2026-07-17T00:00:00.000Z",
    status: "visible",
    reportCount: 0,
  };
  const alice = environment.authenticatedContext("alice").firestore();
  const bob = environment.authenticatedContext("bob").firestore();
  const path = "communityPosts/post-1";
  await assertSucceeds(setDoc(doc(alice, path), validPost));
  await assertFails(setDoc(doc(bob, "communityPosts/forged"), validPost));
  await assertFails(
    updateDoc(doc(bob, path), { status: "removed", body: "" }),
  );
  await assertSucceeds(
    updateDoc(doc(alice, path), { status: "removed", body: "" }),
  );
});

test("private reading groups expose only members and self progress", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "studyGroups/group-1"), {
      name: "Family",
      planId: "plan-1",
      ownerId: "alice",
      memberIds: ["alice", "bob"],
      progressByUser: { alice: 1, bob: 0 },
    });
  });
  const alice = environment.authenticatedContext("alice").firestore();
  const bob = environment.authenticatedContext("bob").firestore();
  const eve = environment.authenticatedContext("eve").firestore();
  const path = "studyGroups/group-1";

  await assertSucceeds(getDoc(doc(bob, path)));
  await assertFails(getDoc(doc(eve, path)));
  await assertSucceeds(
    updateDoc(doc(bob, path), { "progressByUser.bob": 2 }),
  );
  await assertFails(
    updateDoc(doc(bob, path), { "progressByUser.alice": 9 }),
  );
  await assertSucceeds(
    updateDoc(doc(alice, path), { memberIds: ["alice"] }),
  );
});
