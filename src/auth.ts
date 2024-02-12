import NextAuth from "next-auth";
import Github from "next-auth/providers/github";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { db } from "@/db";

// Environment variables for GitHub OAuth credentials
const GITHUB_CLIENT_ID = process.env.GITHUB_CLIENT_ID;
const GITHUB_CLIENT_SECRET = process.env.GITHUB_CLIENT_SECRET;

// Check if GitHub OAuth credentials are set, if not throw an error
if (!GITHUB_CLIENT_ID || !GITHUB_CLIENT_SECRET) {
  throw new Error("Missing GitHub OAuth credentials");
}

// Export the NextAuth handlers and functions
export const {
  handlers: { GET, POST }, // HTTP methods for authentication routes
  auth,                     // Authentication middleware for API routes
  signOut,                  // Sign out function
  signIn,                   // Sign in function
} = NextAuth({
  adapter: PrismaAdapter(db), // Use PrismaAdapter to integrate with the Prisma database
  providers: [
    Github({
      clientId: GITHUB_CLIENT_ID,      // GitHub client ID for OAuth
      clientSecret: GITHUB_CLIENT_SECRET, // GitHub client secret for OAuth
    }),
  ],
  callbacks: {
    // Callback function to fix a bug in NextAuth by adding user ID to the session
    async session({ session, user }: any) {
      if (session && user) {
        session.user.id = user.id; // Add the user ID to the session object
      }
      return session;
    },
  },
});