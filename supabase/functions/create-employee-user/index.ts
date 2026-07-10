import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  if (typeof error === "string") {
    return error;
  }

  try {
    return JSON.stringify(error);
  } catch (_) {
    return "Error desconocido";
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    if (req.method !== "POST") {
      return jsonResponse(
        {
          error: "Método no permitido",
        },
        405,
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(
        {
          error: "Faltan variables de entorno en la Edge Function",
        },
        500,
      );
    }

    const supabaseAdmin = createClient(
      supabaseUrl,
      serviceRoleKey,
    );

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace("Bearer ", "");

    if (!token) {
      return jsonResponse(
        {
          error: "No autorizado",
        },
        401,
      );
    }

    const { data: userData, error: userError } =
      await supabaseAdmin.auth.getUser(token);

    if (userError || !userData.user) {
      return jsonResponse(
        {
          error: "Sesión inválida",
        },
        401,
      );
    }

    const currentUserId = userData.user.id;

    const { data: currentProfile, error: profileError } =
      await supabaseAdmin
        .from("profiles")
        .select("id")
        .eq("user_id", currentUserId)
        .maybeSingle();

    if (profileError || !currentProfile) {
      return jsonResponse(
        {
          error: "Tu usuario no tiene perfil vinculado",
        },
        403,
      );
    }

    const { data: currentEmployee, error: employeePermissionError } =
      await supabaseAdmin
        .from("employees")
        .select("position")
        .eq("profile_id", currentProfile.id)
        .maybeSingle();

    if (employeePermissionError || !currentEmployee) {
      return jsonResponse(
        {
          error: "Tu usuario no está vinculado a un empleado",
        },
        403,
      );
    }

    const allowedPositions = ["Admin", "Gerente"];
    const currentPosition = String(currentEmployee.position ?? "");

    if (!allowedPositions.includes(currentPosition)) {
      return jsonResponse(
        {
          error: "No tienes permisos para crear empleados",
        },
        403,
      );
    }

    const body = await req.json();

    const firstName = String(body.first_name ?? "").trim();
    const lastName = String(body.last_name ?? "").trim();
    const email = String(body.email ?? "").trim().toLowerCase();
    const password = String(body.password ?? "").trim();
    const position = String(body.position ?? "Mesero").trim();
    const hireDate = body.hire_date ?? null;
    const salary = body.salary ?? null;
    const active = body.active ?? true;
    const notes = body.notes ?? null;

    const areas = Array.isArray(body.areas)
      ? body.areas
          .map((area: unknown) => String(area).trim())
          .filter((area: string) => area.length > 0)
      : [];

    if (!firstName || !lastName || !email || !password) {
      return jsonResponse(
        {
          error: "Nombre, apellido, correo y contraseña son obligatorios",
        },
        400,
      );
    }

    if (password.length < 6) {
      return jsonResponse(
        {
          error: "La contraseña debe tener al menos 6 caracteres",
        },
        400,
      );
    }

    if (position === "Mesero" && areas.length === 0) {
      return jsonResponse(
        {
          error: "Selecciona al menos un área para el mesero",
        },
        400,
      );
    }

    const { data: existingEmployee } = await supabaseAdmin
      .from("employees")
      .select("id")
      .eq("email", email)
      .maybeSingle();

    if (existingEmployee) {
      return jsonResponse(
        {
          error: "Ya existe un empleado registrado con ese correo",
        },
        409,
      );
    }

    const { data: authData, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: `${firstName} ${lastName}`.trim(),
          first_name: firstName,
          last_name: lastName,
          position,
        },
      });

    if (authError || !authData.user) {
      return jsonResponse(
        {
          error: authError?.message ?? "No se pudo crear usuario en Auth",
        },
        400,
      );
    }

    const authUserId = authData.user.id;

    let createdEmployeeId: string | null = null;
    // Solo se marca si ESTA petición creó el perfil (no si ya existía uno).
    // Así, en el catch, sólo borramos el perfil que nosotros insertamos y
    // nunca uno preexistente de otro usuario/flujo.
    let createdProfileId: string | null = null;

    try {
      let profileId = "";

      const { data: existingProfile, error: profileSelectError } =
        await supabaseAdmin
          .from("profiles")
          .select("id")
          .eq("user_id", authUserId)
          .maybeSingle();

      if (profileSelectError) {
        throw profileSelectError;
      }

      if (existingProfile?.id) {
        profileId = existingProfile.id;
      } else {
        const { data: profileCreated, error: profileInsertError } =
          await supabaseAdmin
            .from("profiles")
            .insert({
              user_id: authUserId,
              full_name: `${firstName} ${lastName}`.trim(),
            })
            .select("id")
            .single();

        if (profileInsertError) {
          throw profileInsertError;
        }

        profileId = String(profileCreated.id);
        createdProfileId = profileId;
      }

      const { data: employeeCreated, error: employeeError } =
        await supabaseAdmin
          .from("employees")
          .insert({
            profile_id: profileId,
            first_name: firstName,
            last_name: lastName,
            email,
            position,
            hire_date: hireDate,
            salary,
            active,
            notes,
          })
          .select()
          .single();

      if (employeeError) {
        throw employeeError;
      }

      createdEmployeeId = String(employeeCreated.id);

      if (position === "Mesero" && areas.length > 0) {
        const uniqueAreas = [...new Set(areas)];

        const areaRows = uniqueAreas.map((area) => ({
          employee_id: createdEmployeeId,
          area,
        }));

        const { error: areasError } = await supabaseAdmin
          .from("employee_areas")
          .insert(areaRows);

        if (areasError) {
          throw areasError;
        }
      }

      return jsonResponse(
        {
          ok: true,
          auth_user_id: authUserId,
          profile_id: profileId,
          employee: employeeCreated,
        },
        200,
      );
    } catch (dbError) {
      if (createdEmployeeId) {
        await supabaseAdmin
          .from("employee_areas")
          .delete()
          .eq("employee_id", createdEmployeeId);

        await supabaseAdmin
          .from("employees")
          .delete()
          .eq("id", createdEmployeeId);
      }

      if (createdProfileId) {
        await supabaseAdmin
          .from("profiles")
          .delete()
          .eq("id", createdProfileId);
      }

      await supabaseAdmin.auth.admin.deleteUser(authUserId);

      return jsonResponse(
        {
          error:
            `No se pudo completar el registro: ${getErrorMessage(dbError)}`,
        },
        400,
      );
    }
  } catch (e) {
    return jsonResponse(
      {
        error: getErrorMessage(e),
      },
      500,
    );
  }
});