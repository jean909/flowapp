export const ONBOARDING_STORAGE_KEY = 'flow_onboarding_data';

export interface OnboardingData {
  full_name?: string;
  goal?: string;
  gender?: string;
  age?: number;
  current_weight?: number;
  target_weight?: number;
  height?: number;
  activity_level?: string;
  is_smoker?: boolean;
  onboarding_metadata?: Record<string, unknown>;
}

export function getOnboardingFromStorage(): OnboardingData | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = sessionStorage.getItem(ONBOARDING_STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as OnboardingData;
  } catch {
    return null;
  }
}

export function clearOnboardingStorage(): void {
  if (typeof window !== 'undefined') sessionStorage.removeItem(ONBOARDING_STORAGE_KEY);
}

/** Shape for Supabase auth signUp options.data (trigger handle_new_user reads raw_user_meta_data) */
export function onboardingToUserMetadata(data: OnboardingData): Record<string, unknown> {
  return {
    full_name: data.full_name ?? undefined,
    goal: data.goal ?? undefined,
    gender: data.gender ?? undefined,
    age: data.age ?? undefined,
    current_weight: data.current_weight ?? undefined,
    target_weight: data.target_weight ?? undefined,
    height: data.height ?? undefined,
    activity_level: data.activity_level ?? undefined,
    is_smoker: data.is_smoker ?? undefined,
    onboarding_metadata: data.onboarding_metadata ?? {},
  };
}
