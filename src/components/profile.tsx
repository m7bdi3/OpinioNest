"use client";
import { useSession } from "next-auth/react";

export default function Profile() {
  const session = useSession();

  if (session.data?.user) {
    return <div>From Client: {JSON.stringify(session.data.user)} </div>;
  } else {
    return <div>From Client: User is signed out</div>;
  }
}
